.PHONY: launch pause start destroy

launch:
	cd tf && sh launch.sh

pause:
	cd tf && sh pause.sh

start:
	cd tf && sh start.sh

destroy:
	cd tf && sh destroy.sh
