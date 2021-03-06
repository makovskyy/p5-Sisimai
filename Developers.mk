# p5-Sisimai/Developers.mk
#  ____                 _                                       _    
# |  _ \  _____   _____| | ___  _ __   ___ _ __ ___   _ __ ___ | | __
# | | | |/ _ \ \ / / _ \ |/ _ \| '_ \ / _ \ '__/ __| | '_ ` _ \| |/ /
# | |_| |  __/\ V /  __/ | (_) | |_) |  __/ |  \__ \_| | | | | |   < 
# |____/ \___| \_/ \___|_|\___/| .__/ \___|_|  |___(_)_| |_| |_|_|\_\
#                              |_|                                   
# -----------------------------------------------------------------------------
SHELL := /bin/sh
HERE  := $(shell pwd)
NAME  := Sisimai
PERL  ?= perl
MKDIR := mkdir -p
LS    := ls -1
CP    := cp

THELASTBHVER := 2.7.13p3
BOUNCEHAMMER := /usr/local/bouncehammer
MBOXPARSERV0 := $(BOUNCEHAMMER)/bin/mailboxparser -T
MBOXPARSERV6 := $(BOUNCEHAMMER)/bin/mailboxparser -Tvvvvvv
PRECISIONTAB := ANALYTICAL-PRECISION
PARSERLOGDIR := tmp/parser-logs
MAILCLASSDIR := lib/$(NAME)/Bite/Email
JSONCLASSDIR := lib/$(NAME)/Bite/JSON
MTARELATIVES := ARF RFC3464 RFC3834

PRECISIONDIR := tmp/emails-for-precision
COMPARINGDIR := tmp/emails-for-comparing
SAMPLEPREFIX := eml

PARSERSCRIPT := $(PERL) sbin/emparser --delivered
RELEASEVERMP := $(PERL) -MSisimai
DEVELOPVERMP := $(PERL) -I./lib -MSisimai
HOWMANYMAILS := $(DEVELOPVERMP) -lE 'print scalar @{ Sisimai->make(shift, delivered => 1) }' $(COMPARINGDIR)

SET_OF_EMAIL := set-of-emails
PRIVATEMAILS := $(SET_OF_EMAIL)/private
PUBLICEMAILS := $(SET_OF_EMAIL)/maildir/bsd
DOSFORMATSET := $(SET_OF_EMAIL)/maildir/dos
MACFORMATSET := $(SET_OF_EMAIL)/maildir/mac

INDEX_LENGTH := 24
DESCR_LENGTH := 50
BH_CAN_PARSE := AmazonSES AmazonWorkMail Aol Bigfoot Biglobe Courier EZweb Exim \
				Facebook GSuite Google KDDI MessageLabs MessagingServer Office365 \
				Postfix SendGrid Sendmail Verizon X5 Yandex qmail
REASON_TABLE := Blocked ContentError Delivered ExceedLimit Expired Feedback Filtered \
				HasMoved HostUnknown MailboxFull MailerError MesgTooBig NetworkError \
				NoRelaying NotAccept OnHold PolicyViolation Rejected SecurityError \
				SpamDetected Suspend SyntaxError SystemError SystemFull TooManyConn	\
				Undefined UserUnknown Vacation VirusDetected

# -----------------------------------------------------------------------------
.PHONY: clean

private-sample:
	@test -n "$(E)" || ( echo 'Usage: make -f Developers.mk $@ E=/path/to/email' && exit 1 )
	@test -x sbin/emparser
	test -f $(E)
	$(PARSERSCRIPT) $(E)
	@echo
	@while true; do \
		d=`$(PARSERSCRIPT) -Fjson $(E) | jq -M '.[].smtpagent' | head -1 \
			| tr '[A-Z]' '[a-z]' | tr -d '-' | sed -e 's/"//g' -e 's/::/-/g'`; \
		if [ -d "$(PRIVATEMAILS)/$$d" ]; then \
			latestfile=`ls -1 $(PRIVATEMAILS)/$$d/*.$(SAMPLEPREFIX) | tail -1`; \
			curr_index=`basename $$latestfile | cut -d'-' -f1`; \
			next_index=`echo $$curr_index + 1 | bc`; \
		else \
			$(MKDIR) $(PRIVATEMAILS)/$$d; \
			next_index=1001; \
		fi; \
		hash_value=`md5 -q $(E)`; \
		if [ -n "`ls -1 $(PRIVATEMAILS)/$$d/ | grep $$hash_value`" ]; then \
			echo 'Already exists:' `ls -1 $(PRIVATEMAILS)/$$d/*$$hash_value.$(SAMPLEPREFIX)`; \
		else \
			printf "[%05d] %s %s\n" $$next_index $$hash_value; \
			mv -v $(E) $(PRIVATEMAILS)/$$d/0$${next_index}-$${hash_value}.$(SAMPLEPREFIX); \
		fi; \
		break; \
	done

precision-table: emails-for-precision
	@ printf " %s\n" 'bounceHammer $(THELASTBHVER)'
	@ printf " %s\n" 'MTA MODULE NAME          CAN PARSE   RATIO   NOTES'
	@ printf "%s\n" '--------------------------------------------------------------------------------'
	@ for v in `$(LS) ./$(MAILCLASSDIR)/*.pm | grep -v 'UserDefined'`; do \
		m="Email::`echo $$v | cut -d/ -f6 | sed 's/.pm//g'`" ;\
		d="`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.pm//g'`" ;\
		l="`echo $$m | wc -c`" ;\
		printf "%s " $$m ;\
		while [ $$l -le $(INDEX_LENGTH) ]; do \
			printf "%s" '.' ;\
			l=`expr $$l + 1` ;\
		done ;\
		printf "%s" ' ' ;\
		n0=`$(PARSERSCRIPT) --count-only $(PRECISIONDIR)/email-$$d` ;\
		r0=`$(MBOXPARSERV6) $(PRECISIONDIR)/email-$$d 2>&1 | grep 'debug0:' \
			| sed 's/^.*debug0:/0 /g' | cut -d' ' -f9,10` ;\
		rn="`echo $$r0 | cut -d/ -f1`" ;\
		if [ $$rn -lt $$n0 ]; then \
			rr=`$(PERL) -le "printf('%.4f', $$rn / $$n0 );"`; \
		else \
			rr='1.0000'; \
		fi; \
		printf "%4d/%04d  %s  " $$rn $$n0 $$rr ;\
		$(PERL) -Ilib -MSisimai::Bite::$$m -lE "print Sisimai::Bite::$$m->description" ;\
	done
	@ for v in `$(LS) ./$(JSONCLASSDIR)/*.pm`; do \
		m="JSON::`echo $$v | cut -d/ -f6 | sed 's/.pm//g'`" ;\
		d="`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.pm//g'`" ;\
		l="`echo $$m | wc -c`" ;\
		printf "%s " $$m ;\
		while [ $$l -le $(INDEX_LENGTH) ]; do \
			printf "%s" '.' ;\
			l=`expr $$l + 1` ;\
		done ;\
		printf "%s" ' ' ;\
		n0=`$(PARSERSCRIPT) --count-only $(PRECISIONDIR)/email-$$d` ;\
		r0=`$(MBOXPARSERV6) $(PRECISIONDIR)/email-$$d 2>&1 | grep 'debug0:' \
			| sed 's/^.*debug0:/0 /g' | cut -d' ' -f9,10` ;\
		rn="`echo $$r0 | cut -d/ -f1`" ;\
		if [ $$rn -lt $$n0 ]; then \
			rr=`$(PERL) -le "printf('%.4f', $$rn / $$n0 );"`; \
		else \
			rr='1.0000'; \
		fi; \
		printf "%4d/%04d  %s  " $$rn $$n0 $$rr ;\
		$(PERL) -Ilib -MSisimai::Bite::$$m -lE "print Sisimai::Bite::$$m->description" ;\
	done
	@ for v in $(MTARELATIVES); do \
		m=$$v ;\
		d="`echo $$v | tr '[A-Z]' '[a-z]'`" ;\
		l="`echo $$m | wc -c`" ;\
		printf "%s " $$m ;\
		while [ $$l -le $(INDEX_LENGTH) ]; do \
			printf "%s" '.' ;\
			l=`expr $$l + 1` ;\
		done ;\
		printf "%s" ' ' ;\
		n0=`$(PARSERSCRIPT) --count-only $(PRECISIONDIR)/$$d` ;\
		r0=`$(MBOXPARSERV6) $(PRECISIONDIR)/$$d 2>&1 | grep 'debug0:' \
			| sed 's/^.*debug0:/0 /g' | cut -d' ' -f9,10` ;\
		rn="`echo $$r0 | cut -d/ -f1`" ;\
		if [ $$rn -lt $$n0 ]; then \
			rr=`$(PERL) -le "printf('%.4f', $$rn / $$n0 );"`; \
		else \
			rr='1.0000'; \
		fi; \
		printf "%4d/%04d  %s  " $$rn $$n0 $$rr ;\
		$(PERL) -Ilib -MSisimai::$$m -lE "print Sisimai::$$m->description" ;\
	done
	@ printf "%s\n" '--------------------------------------------------------------------------------'

update-analytical-precision-table: emails-for-precision
	$(CP) /dev/null $(PRECISIONTAB)
	$(MAKE) -f Developers.mk precision-table 2> /dev/null >> $(PRECISIONTAB)
	grep '^[A-Z]' ./$(PRECISIONTAB) | tr '/' ' ' | \
		awk ' { \
				x += $$3; \
				y += $$4; \
			} END { \
				sisimai_cmd = "$(PERL) -Ilib -M$(NAME) -E '\''print $(NAME)->version'\''"; \
				sisimai_cmd | getline sisimai_ver; \
				close(sisimai_cmd); \
				printf(" %s %4d/%04d  %0.4f\n %s %s %9s %4d/%04d  %0.4f\n", \
					"bounceHammer $(THELASTBHVER)   ", x, y, x / y, \
					"Sisimai", sisimai_ver, " ", y, y, 1 ); \
			} ' \
			>> $(PRECISIONTAB)

mta-module-table:
	@ printf "%s\n"  '| Module (Sisimai::Bite)   | Description                                         |'
	@ printf "%s\n"  '|--------------------------|-----------------------------------------------------|'
	@ for v in `$(LS) ./$(MAILCLASSDIR)/*.pm | grep -v UserDefined`; do \
		m="Email::`echo $$v | cut -d/ -f6 | sed 's/.pm//g'`" ;\
		d="`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.pm//g'`" ;\
		l="`echo $$m | wc -c`" ;\
		printf "| %s " $$m ;\
		while [ $$l -le $(INDEX_LENGTH) ]; do \
			printf "%s" ' ' ;\
			l=`expr $$l + 1` ;\
		done ;\
		printf "%s" '|' ;\
		r=`$(PERL) -Ilib -MSisimai::Bite::$$m -le "print Sisimai::Bite::$$m->description"` ;\
		x="`echo $$r | wc -c`" ;\
		printf " %s" $$r ;\
		while [ $$x -le $(DESCR_LENGTH) ]; do \
			printf "%s" ' ' ;\
			x=`expr $$x + 1` ;\
		done ;\
		printf " %s\n" ' |' ;\
	done
	@ for v in `$(LS) ./$(JSONCLASSDIR)/*.pm`; do \
		m="JSON::`echo $$v | cut -d/ -f6 | sed 's/.pm//g'`" ;\
		d="`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.pm//g'`" ;\
		l="`echo $$m | wc -c`" ;\
		printf "| %s " $$m ;\
		while [ $$l -le $(INDEX_LENGTH) ]; do \
			printf "%s" ' ' ;\
			l=`expr $$l + 1` ;\
		done ;\
		printf "%s" '|' ;\
		r=`$(PERL) -Ilib -MSisimai::Bite::$$m -le "print Sisimai::Bite::$$m->description"` ;\
		x="`echo $$r | wc -c`" ;\
		printf " %s" $$r ;\
		while [ $$x -le $(DESCR_LENGTH) ]; do \
			printf "%s" ' ' ;\
			x=`expr $$x + 1` ;\
		done ;\
		printf " %s\n" ' |' ;\
	done
	@ for v in $(MTARELATIVES); do \
		m=$$v ;\
		d="`echo $$v | tr '[A-Z]' '[a-z]'`" ;\
		l="`echo $$m | wc -c`" ;\
		printf "| %s " $$m ;\
		while [ $$l -le $(INDEX_LENGTH) ]; do \
			printf "%s" ' ' ;\
			l=`expr $$l + 1` ;\
		done ;\
		printf "%s" '|' ;\
		r=`$(PERL) -Ilib -MSisimai::$$m -lE "print Sisimai::$$m->description"` ;\
		x="`echo $$r | wc -c`" ;\
		printf " %s" $$r ;\
		while [ $$x -le $(DESCR_LENGTH) ]; do \
			printf "%s" ' ' ;\
			x=`expr $$x + 1` ;\
		done ;\
		printf " %s\n" ' |' ;\
	done

update-other-format-emails:
	for v in `find $(PUBLICEMAILS) -name '*-01.eml' -type f`; do \
		f="`basename $$v`" ;\
		nkf -Lw $$v > $(DOSFORMATSET)/$$f ;\
		nkf -Lm $$v > $(MACFORMATSET)/$$f ;\
	done

emails-for-precision:
	for v in `$(LS) ./$(MAILCLASSDIR)/*.pm | grep -v UserDefined`; do \
		MTA=`echo $$v | cut -d/ -f6 | tr '[A-Z]' '[a-z]' | sed 's/.pm//g'` ;\
		$(MKDIR) $(PRECISIONDIR)/email-$$MTA ;\
		$(CP) $(PUBLICEMAILS)/email-$$MTA-*.eml $(PRECISIONDIR)/email-$$MTA/ ;\
		$(CP) $(PRIVATEMAILS)/email-$$MTA/* $(PRECISIONDIR)/email-$$MTA/ ;\
	done
	for v in arf rfc3464 rfc3834; do \
		$(MKDIR) $(PRECISIONDIR)/$$v ;\
		$(CP) $(PUBLICEMAILS)/$$v*.eml $(PRECISIONDIR)/$$v/ ;\
		$(CP) $(PRIVATEMAILS)/$$v/* $(PRECISIONDIR)/$$v/ ;\
	done

parser-log:
	$(MKDIR) $(PARSERLOGDIR)
	test -d $(PRIVATEMAILS)
	for v in `$(LS) $(PRIVATEMAILS)`; do \
		$(CP) /dev/null $(PARSERLOGDIR)/$$v.log; \
		for r in `find $(PRIVATEMAILS)/$$v -type f -name '*.eml'`; do \
			echo $$r; \
			echo $$r >> $(PARSERLOGDIR)/$$v.log; \
			$(PARSERSCRIPT) -Fddp $$r | grep -E 'reason|diagnosticcode|deliverystatus' >> $(PARSERLOGDIR)/$$v.log; \
			echo >> $(PARSERLOGDIR)/$$v.log; \
		done; \
	done

emails-for-comparing:
	@ rm -fr ./$(COMPARINGDIR)
	@ $(MKDIR) $(COMPARINGDIR)
	@ for v in $(BH_CAN_PARSE); do \
		$(CP) $(PUBLICEMAILS)/email-`echo $$v | tr '[A-Z]' '[a-z]'`-*.eml $(COMPARINGDIR)/; \
		test -d $(PRIVATEEMAILS) && $(CP) $(PRIVATEMAILS)/email-`echo $$v | tr '[A-Z]' '[a-z]'`/*.eml $(COMPARINGDIR)/; \
	done

comparison: emails-for-comparing
	@ echo -------------------------------------------------------------------
	@ echo `$(HOWMANYMAILS)` emails in $(COMPARINGDIR)
	@ echo -n 'Calculating the velocity of parsing 1000 mails: multiply by '
	@ echo "scale=6; 1000 / `$(HOWMANYMAILS)`" | bc
	@ echo -------------------------------------------------------------------
	@ uptime
	@ echo -------------------------------------------------------------------
	@ if [ -x "$(BOUNCEHAMMER)/bin/mailboxparser" ]; then \
		echo bounceHammer $(THELASTBHVER); \
		n=1; while [ $$n -le 5 ]; do \
			/usr/bin/time $(MBOXPARSERV0) -Fjson $(COMPARINGDIR) > /dev/null ;\
			sleep 1; \
			n=`expr $$n + 1`; \
		done; \
		echo -------------------------------------------------------------------; \
	fi
	@ echo 'Sisimai' `$(RELEASEVERMP) -le 'print Sisimai->version'` $(RELEASEVERMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(RELEASEVERMP) -lE 'Sisimai->make(shift, "deliverd" => 1)' $(COMPARINGDIR) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------
	@ echo 'Sisimai' `$(DEVELOPVERMP) -le 'print Sisimai->version'` $(DEVELOPVERMP)
	@ n=1; while [ $$n -le 5 ]; do \
		/usr/bin/time $(DEVELOPVERMP) -lE 'Sisimai->make(shift, "deliverd" => 1)' $(COMPARINGDIR) > /dev/null ;\
		sleep 1; \
		n=`expr $$n + 1`; \
	done
	@ echo -------------------------------------------------------------------

reason-coverage:
	@ for v in `ls -1 $(MAILCLASSDIR) | grep -v UserDefined | sort | tr '[A-Z]' '[a-z]' | sed -e 's|.pm||g' -e 's|^|bite-email-|g'`; do \
		for e in `echo $(REASON_TABLE) | tr '[A-Z]' '[a-z]'`; do \
			printf "%d," `grep $$e t/*-$$v.t | wc -l`; \
		done; \
		echo; \
	done
	@ for v in `ls -1 $(JSONCLASSDIR) | sort | tr '[A-Z]' '[a-z]' | sed -e 's|.pm||g' -e 's|^|bite-json-|g'`; do \
		for e in `echo $(REASON_TABLE) | tr '[A-Z]' '[a-z]'`; do \
			printf "%d," `grep $$e t/*-$$v.t | wc -l`; \
		done; \
		echo; \
	done
	@ for v in rfc3464 rfc3834 arf mda; do \
		for e in `echo $(REASON_TABLE) | tr '[A-Z]' '[a-z]'`; do \
			printf "%d," `grep $$e t/*-$$v.t | wc -l`; \
		done; \
		echo; \
	done

header-content-list: emails-for-precision
	/bin/cp /dev/null ./subject-list
	/bin/cp /dev/null ./senders-list
	for v in `ls -1 $(PRECISIONDIR) | grep -v rfc | grep -v arf`; do \
		for w in `find $(PRECISIONDIR)/$$v -type f`; do \
			grep '^Subject:' $$w | head -1 | sed -e "s/^Subject:/[$$v]/g" >> ./subject-list; \
			grep '^From: ' $$w | head -1 | sed -e "s/^From:/[$$v]/g" >> ./senders-list; \
		done; \
	done
	cat subject-list | sort | uniq > tmp/subject-list
	cat senders-list | sort | uniq > tmp/senders-list
	rm ./subject-list ./senders-list

clean:
	$(RM) -r cover_db
	$(RM) -r ./build
	$(RM) -r ./$(PRECISIONDIR)
	$(RM) -r ./$(COMPARINGDIR)
	$(RM) -f tmp/subject-list tmp/senders-list

