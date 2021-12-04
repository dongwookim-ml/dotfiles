#!/bin/sh

if [ "$#" -gt 0 ]
then
    ssh u1009226@"$1" 'screen -d -m /localdata/u1009226/miniconda3/bin/jupyter notebook --no-browser --port=8333'
    ssh -N -f -L localhost:8071:localhost:8333 u1009226@"$1"
else
    ssh u1009226@cray 'screen -d -m /localdata/u1009226/miniconda3/bin/jupyter notebook --no-browser --port=8333'
    ssh -N -f -L localhost:8071:localhost:8333 u1009226@cray
fi

