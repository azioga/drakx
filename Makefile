BOOT_IMG = gi_hd.img gi_cdrom.img gi_network.img gi_network_ks.img gi_pcmcia.img gi_pcmcia_ks.img
BINS = install/install install/local-install install/installinit/init
DIRS = install install/installinit mouseconfig perl-install ddcprobe lnx4win


.PHONY: dirs $(FLOPPY_IMG)

install: build
	mkdir -p /export/images 2>/dev/null ||:
	cp -f $(BOOT_IMG) /export/images
	make -C perl-install full_stage2

build: dirs $(BOOT_IMG)

dirs:
	for i in $(DIRS); do make -C $$i; done

$(BOOT_IMG): modules
	make dirs
	./make_boot_img $@ $(@:gi_%.img=%)

tar: clean
	cd .. ; tar cfy gi.tar.bz2 gi

modules: kernel/lib/modules
	./update_kernel

$(BOOT_IMG:%=%f): %f: %
	dd if=$< of=/dev/fd0
	xmessage "Floppy done"

clean:
	rm -rf $(BOOT_IMG) $(BINS) modules install_pcmcia_modules vmlinuz System.map
	rm -rf install/*/sbin/install install/*/sbin/init
	for i in $(DIRS); do make -C $$i clean; done
	find . -name "*~" -o -name ".#*" | xargs rm -f

upload: tar install
	touch /tmp/mdkinst_done
	rm ~/gi/*_ks.img
	cd /export/Mandrake ; tar cfz mdkinst.tgz mdkinst

#	lftp -c "open -u devel mandrakesoft.com; cd ~/cooker/cooker/images ; mput ~/gi/gi_*.img ;"
	lftp -c "open -u devel mandrakesoft.com; cd ~/tmp ; put /export/Mandrake/mdkinst.tgz ; put /tmp/mdkinst_done ; cd ~/cooker/cooker/Mandrake/base ; put /export/Mandrake/base/mdkinst_stage2.gz ; put ~/gi/perl-install/compss ; put ~/gi/perl-install/compssList ; put ~/gi/perl-install/compssUsers "
#	lftp -c "open -u devel mandrakesoft.com; cd ~/cooker/contrib/others/src ; put ~/gi.tar.bz2"
	rm -f /export/Mandrake/mdkinst.tgz
	rm -f /tmp/mdkinst_done

# mkisofs -R -b images/gi_cdrom.img -c images/.catalog /tmp/r /mnt/disk/ | cdrecord -v -eject speed=6 dev=1,0 -
