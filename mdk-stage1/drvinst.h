/*
 * Per Øyvind Karlsen <peroyvind@mandriva.org>
 * Copyright 2012 Mandriva
 *
 * This software may be freely redistributed under the terms of the GNU
 * public license.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#ifndef _DRVINST_H_
#define _DRVINST_H_

int modprobe(const char *alias);
int drvinst_main(int argc, char *argv[]);

#endif
