# Creating the inventory file for Ansible

# In case you run this Setup multiple times, empty your know hosts file.
# mv ~/.ssh/known_hosts /tmp/known_hosts 
terraform output -json | jq -r '.web_server_ips.value[]' > ../ansible-config/inventory
export ANSIBLE_HOST_KEY_CHECKING=False
