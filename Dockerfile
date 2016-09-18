FROM scratch

ADD bin/daemon /daemon

ENTRYPOINT ["/daemon"]
