#!/usr/bin/env bash

for i in {0..2}
do
    # sed -i '' /^kates-server-${i}.flight.kja.us/d $HOME/.ssh/known_hosts
    ssh-keygen -R kates-server-${i}.flight.kja.us -f $HOME/.ssh/known_hosts
    ssh-keyscan kates-server-${i}.flight.kja.us >> $HOME/.ssh/known_hosts
done

for i in {0..2}
do
    # sed -i '' /^kates-worker-${i}.flight.kja.us/d $HOME/.ssh/known_hosts
    ssh-keygen -R kates-worker-${i}.flight.kja.us -f $HOME/.ssh/known_hosts
    ssh-keyscan kates-worker-${i}.flight.kja.us >> $HOME/.ssh/known_hosts
done
