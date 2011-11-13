HARNESS=TAP::Harness
HARNESS_EVAL=${HARNESS}->new->runtests(qw(${TESTS}))
HARNESS_RUN=perl -M${HARNESS} -e '${HARNESS_EVAL}'
TESTS=$(wildcard t/*.t)

test:
	${HARNESS_RUN}
