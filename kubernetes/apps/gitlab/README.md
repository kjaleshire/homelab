# GitLab

## To install the GitLab Kubernetes Agent client

Go to the provisioning project in GitLab, Operate dropdown, Kubernetes clusters tab, and connect a new cluster. Set the agent name, token & run `helm` as follows:

```fish
set AGENT_NAME <agent name here>
set TOKEN <token here>
helm upgrade --install $AGENT_NAME gitlab/gitlab-agent \
             --namespace gitlab-agent-$AGENT_NAME \
             --create-namespace \
             --set image.tag=v16.3.0 \
             --set config.token=$TOKEN \
             --set config.kasAddress=wss://gitlab.flight.kja.us/kas/ \
             --set replicas=1
```
