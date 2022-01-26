FROM quay.io/operator-framework/ansible-operator:v1.6.1

# export proxy
ENV https_proxy "http://pbpr-epic-squid.apple.com:3128"
ENV http_proxy  "http://pbpr-epic-squid.apple.com:3128"

copy ansible_cfg ${HOME}/ansible.cfg

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
