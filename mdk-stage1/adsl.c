/*
 * Guillaume Cottenceau (gc@mandrakesoft.com)
 *
 * Copyright 2000 MandrakeSoft
 *
 * This software may be freely redistributed under the terms of the GNU
 * public license.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <stdio.h>
#include <resolv.h>
#include <signal.h>

#include "stage1.h"
#include "log.h"
#include "network.h"
#include "modules.h"
#include "tools.h"
#include "frontend.h"
#include "automatic.h"

#include "adsl.h"


static enum return_type adsl_connect(char * net_device, char * username, char * password)
{
	char pppoe_call[500];
	char * pppd_launch[] = { "/sbin/pppd", "pty", pppoe_call, "noipdefault", "noauth", "default-asyncmap", "defaultroute",
				 "hide-password", "nodetach", "usepeerdns", "local", "mtu", "1492", "mru", "1492", "noaccomp",
				 "noccp", "nobsdcomp", "nodeflate", "nopcomp", "novj", "novjccomp", "user", username,
				 "password", password, "lcp-echo-interval", "20", "lcp-echo-failure", "3", "lock", "persist", NULL };
	int fd;
	int retries = 10;
	char * tty_adsl = "/dev/tty6";
	enum return_type status = RETURN_ERROR;
	pid_t ppp_pid;

	snprintf(pppoe_call, sizeof(pppoe_call), "/sbin/pppoe -p /var/run/pppoe.conf-adsl.pid.pppoe -I %s -T 80 -U -m 1412", net_device);


	fd = open(tty_adsl, O_RDWR);
	if (fd == -1) {
		log_message("cannot open tty -- no pppd");
		return RETURN_ERROR;
	}
	else if (access(pppd_launch[0], X_OK)) {
		log_message("cannot open pppd - %s doesn't exist", pppd_launch[0]);
		return RETURN_ERROR;
	}

	if (!(ppp_pid = fork())) {
		dup2(fd, 0);
		dup2(fd, 1);
		dup2(fd, 2);
		
		close(fd);
		setsid();
		if (ioctl(0, TIOCSCTTY, NULL))
			log_perror("could not set new controlling tty");
		
		printf("\t(exec of pppd)\n");
		execve(pppd_launch[0], pppd_launch, grab_env());
		log_message("execve of %s failed: %s", pppd_launch[0], strerror(errno));
		exit(-1);
	}
	close(fd);
	while (retries > 0 && kill(ppp_pid, 0) == 0) {
		FILE * f;
		if ((f = fopen("/var/run/pppd.tdb", "rb"))) {
			while (1) {
				char buf[500];
				if (!fgets(buf, sizeof(buf), f))
					break;
				if (strstr(buf, "IPLOCAL="))
					status = RETURN_OK;
			}
			fclose(f);
			if (status == RETURN_OK) {
				log_message("PPP: connected!");
				break;
			}
		}
		retries--;
		log_message("PPP: <sleep>");
		sleep(2);
	}

	if (status != RETURN_OK) {
		log_message("PPP: could not connect");
		kill(ppp_pid, SIGTERM);
		sleep(1);
		kill(ppp_pid, SIGKILL);
		sleep(1);
	}
	return status;
}


enum return_type perform_adsl(struct interface_info * intf)
{
	struct in_addr addr;
	char * questions[] = { "Username", "Password", NULL };
	char * questions_auto[] = { "user", "pass", NULL };
	static char ** answers = NULL;
	enum return_type results;

	if (strncmp(intf->device, "eth", 3)) {
		stg1_error_message("ADSL available only for Ethernet networking (through PPPoE).");
		return RETURN_ERROR;
	}

	inet_aton("10.0.0.10", &addr);
	memcpy(&intf->ip, &addr, sizeof(addr));

	inet_aton("255.255.255.0", &addr);
	memcpy(&intf->netmask, &addr, sizeof(addr));

	*((uint32_t *) &intf->broadcast) = (*((uint32_t *) &intf->ip) &
					    *((uint32_t *) &intf->netmask)) | ~(*((uint32_t *) &intf->netmask));

	intf->is_ptp = 0;

	if (configure_net_device(intf)) {
		stg1_error_message("Could not configure..");
		return RETURN_ERROR;
	}

	results = ask_from_entries_auto("Please enter the username and password for your ADSL account.\n"
					"(Warning! only PPPoE protocol is supported)",
					questions, &answers, 40, questions_auto, NULL);
	if (results != RETURN_OK)
		return results;

	wait_message("Waiting for ADSL connection to show up...");
	my_insmod("ppp_generic", ANY_DRIVER_TYPE, NULL);
	my_insmod("ppp_async", ANY_DRIVER_TYPE, NULL);
	my_insmod("ppp", ANY_DRIVER_TYPE, NULL);
	results = adsl_connect(intf->device, answers[0], answers[1]);
	remove_wait_message();

	if (results != RETURN_OK) {
		wait_message("Retrying the ADSL connection...");
		results = adsl_connect(intf->device, answers[0], answers[1]);
		remove_wait_message();
	}

	if (results != RETURN_OK) {
		stg1_error_message("I could not connect to the ADSL network.");
		return perform_adsl(intf);
	}

	sleep(1);
	res_init();		/* reinit the resolver, pppd modified /etc/resolv.conf */

	return RETURN_OK;
}
