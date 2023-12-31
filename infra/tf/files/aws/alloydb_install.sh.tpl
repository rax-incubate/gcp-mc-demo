#!/bin/bash

# This script is used to install AlloyDB OMNI on an EC2 instance. See README.md at the top level of the repo for more details

#Base packages
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common net-tools postgresql-client apt-transport-https ca-certificates gnupg

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
sudo apt install -y docker-ce 

# Get alloydb docker images
sudo docker pull gcr.io/alloydb-omni/pg-service:latest
sudo docker pull gcr.io/alloydb-omni/memory-agent:latest

# Install gcloud 
echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install -y google-cloud-cli 

# Download the AlloyDB installer script and run it
gsutil cp -r gs://alloydb-omni-install/$(gsutil cat gs://alloydb-omni-install/latest) .
cd $(gsutil cat gs://alloydb-omni-install/latest)
tar -xzf alloydb_omni_installer.tar.gz && cd installer
sudo bash install_alloydb.sh

# Setup data disk
sudo mkfs.ext4 ${env2_alloydb_data_device_name}
sudo mkdir /data
sudo mount ${env2_alloydb_data_device_name} /data

# Update config in dataplane.conf
sudo sed -i "s|^\(DATADIR_PATH=\).*|\1/data|" /var/alloydb/config/dataplane.conf

# Copy our vesion of pg_hba.conf. See pg_hba.conf for details. 
echo "IyBQb3N0Z3JlU1FMIENsaWVudCBBdXRoZW50aWNhdGlvbiBDb25maWd1cmF0aW9uIEZpbGUKIyA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0KIwojIFJlZmVyIHRvIHRoZSAiQ2xpZW50IEF1dGhlbnRpY2F0aW9uIiBzZWN0aW9uIGluIHRoZSBQb3N0Z3JlU1FMCiMgZG9jdW1lbnRhdGlvbiBmb3IgYSBjb21wbGV0ZSBkZXNjcmlwdGlvbiBvZiB0aGlzIGZpbGUuICBBIHNob3J0CiMgc3lub3BzaXMgZm9sbG93cy4KIwojIFRoaXMgZmlsZSBjb250cm9sczogd2hpY2ggaG9zdHMgYXJlIGFsbG93ZWQgdG8gY29ubmVjdCwgaG93IGNsaWVudHMKIyBhcmUgYXV0aGVudGljYXRlZCwgd2hpY2ggUG9zdGdyZVNRTCB1c2VyIG5hbWVzIHRoZXkgY2FuIHVzZSwgd2hpY2gKIyBkYXRhYmFzZXMgdGhleSBjYW4gYWNjZXNzLiAgUmVjb3JkcyB0YWtlIG9uZSBvZiB0aGVzZSBmb3JtczoKIwojIGxvY2FsICAgICAgICAgREFUQUJBU0UgIFVTRVIgIE1FVEhPRCAgW09QVElPTlNdCiMgaG9zdCAgICAgICAgICBEQVRBQkFTRSAgVVNFUiAgQUREUkVTUyAgTUVUSE9EICBbT1BUSU9OU10KIyBob3N0c3NsICAgICAgIERBVEFCQVNFICBVU0VSICBBRERSRVNTICBNRVRIT0QgIFtPUFRJT05TXQojIGhvc3Rub3NzbCAgICAgREFUQUJBU0UgIFVTRVIgIEFERFJFU1MgIE1FVEhPRCAgW09QVElPTlNdCiMgaG9zdGdzc2VuYyAgICBEQVRBQkFTRSAgVVNFUiAgQUREUkVTUyAgTUVUSE9EICBbT1BUSU9OU10KIyBob3N0bm9nc3NlbmMgIERBVEFCQVNFICBVU0VSICBBRERSRVNTICBNRVRIT0QgIFtPUFRJT05TXQojCiMgKFRoZSB1cHBlcmNhc2UgaXRlbXMgbXVzdCBiZSByZXBsYWNlZCBieSBhY3R1YWwgdmFsdWVzLikKIwojIFRoZSBmaXJzdCBmaWVsZCBpcyB0aGUgY29ubmVjdGlvbiB0eXBlOgojIC0gImxvY2FsIiBpcyBhIFVuaXgtZG9tYWluIHNvY2tldAojIC0gImhvc3QiIGlzIGEgVENQL0lQIHNvY2tldCAoZW5jcnlwdGVkIG9yIG5vdCkKIyAtICJob3N0c3NsIiBpcyBhIFRDUC9JUCBzb2NrZXQgdGhhdCBpcyBTU0wtZW5jcnlwdGVkCiMgLSAiaG9zdG5vc3NsIiBpcyBhIFRDUC9JUCBzb2NrZXQgdGhhdCBpcyBub3QgU1NMLWVuY3J5cHRlZAojIC0gImhvc3Rnc3NlbmMiIGlzIGEgVENQL0lQIHNvY2tldCB0aGF0IGlzIEdTU0FQSS1lbmNyeXB0ZWQKIyAtICJob3N0bm9nc3NlbmMiIGlzIGEgVENQL0lQIHNvY2tldCB0aGF0IGlzIG5vdCBHU1NBUEktZW5jcnlwdGVkCiMKIyBEQVRBQkFTRSBjYW4gYmUgImFsbCIsICJzYW1ldXNlciIsICJzYW1lcm9sZSIsICJyZXBsaWNhdGlvbiIsIGEKIyBkYXRhYmFzZSBuYW1lLCBvciBhIGNvbW1hLXNlcGFyYXRlZCBsaXN0IHRoZXJlb2YuIFRoZSAiYWxsIgojIGtleXdvcmQgZG9lcyBub3QgbWF0Y2ggInJlcGxpY2F0aW9uIi4gQWNjZXNzIHRvIHJlcGxpY2F0aW9uCiMgbXVzdCBiZSBlbmFibGVkIGluIGEgc2VwYXJhdGUgcmVjb3JkIChzZWUgZXhhbXBsZSBiZWxvdykuCiMKIyBVU0VSIGNhbiBiZSAiYWxsIiwgYSB1c2VyIG5hbWUsIGEgZ3JvdXAgbmFtZSBwcmVmaXhlZCB3aXRoICIrIiwgb3IgYQojIGNvbW1hLXNlcGFyYXRlZCBsaXN0IHRoZXJlb2YuICBJbiBib3RoIHRoZSBEQVRBQkFTRSBhbmQgVVNFUiBmaWVsZHMKIyB5b3UgY2FuIGFsc28gd3JpdGUgYSBmaWxlIG5hbWUgcHJlZml4ZWQgd2l0aCAiQCIgdG8gaW5jbHVkZSBuYW1lcwojIGZyb20gYSBzZXBhcmF0ZSBmaWxlLgojCiMgQUREUkVTUyBzcGVjaWZpZXMgdGhlIHNldCBvZiBob3N0cyB0aGUgcmVjb3JkIG1hdGNoZXMuICBJdCBjYW4gYmUgYQojIGhvc3QgbmFtZSwgb3IgaXQgaXMgbWFkZSB1cCBvZiBhbiBJUCBhZGRyZXNzIGFuZCBhIENJRFIgbWFzayB0aGF0IGlzCiMgYW4gaW50ZWdlciAoYmV0d2VlbiAwIGFuZCAzMiAoSVB2NCkgb3IgMTI4IChJUHY2KSBpbmNsdXNpdmUpIHRoYXQKIyBzcGVjaWZpZXMgdGhlIG51bWJlciBvZiBzaWduaWZpY2FudCBiaXRzIGluIHRoZSBtYXNrLiAgQSBob3N0IG5hbWUKIyB0aGF0IHN0YXJ0cyB3aXRoIGEgZG90ICguKSBtYXRjaGVzIGEgc3VmZml4IG9mIHRoZSBhY3R1YWwgaG9zdCBuYW1lLgojIEFsdGVybmF0aXZlbHksIHlvdSBjYW4gd3JpdGUgYW4gSVAgYWRkcmVzcyBhbmQgbmV0bWFzayBpbiBzZXBhcmF0ZQojIGNvbHVtbnMgdG8gc3BlY2lmeSB0aGUgc2V0IG9mIGhvc3RzLiAgSW5zdGVhZCBvZiBhIENJRFItYWRkcmVzcywgeW91CiMgY2FuIHdyaXRlICJzYW1laG9zdCIgdG8gbWF0Y2ggYW55IG9mIHRoZSBzZXJ2ZXIncyBvd24gSVAgYWRkcmVzc2VzLAojIG9yICJzYW1lbmV0IiB0byBtYXRjaCBhbnkgYWRkcmVzcyBpbiBhbnkgc3VibmV0IHRoYXQgdGhlIHNlcnZlciBpcwojIGRpcmVjdGx5IGNvbm5lY3RlZCB0by4KIwojIE1FVEhPRCBjYW4gYmUgInRydXN0IiwgInJlamVjdCIsICJtZDUiLCAicGFzc3dvcmQiLCAic2NyYW0tc2hhLTI1NiIsCiMgImdzcyIsICJzc3BpIiwgImlkZW50IiwgInBlZXIiLCAicGFtIiwgImxkYXAiLCAicmFkaXVzIiBvciAiY2VydCIuCiMgTm90ZSB0aGF0ICJwYXNzd29yZCIgc2VuZHMgcGFzc3dvcmRzIGluIGNsZWFyIHRleHQ7ICJtZDUiIG9yCiMgInNjcmFtLXNoYS0yNTYiIGFyZSBwcmVmZXJyZWQgc2luY2UgdGhleSBzZW5kIGVuY3J5cHRlZCBwYXNzd29yZHMuCiMKIyBPUFRJT05TIGFyZSBhIHNldCBvZiBvcHRpb25zIGZvciB0aGUgYXV0aGVudGljYXRpb24gaW4gdGhlIGZvcm1hdAojIE5BTUU9VkFMVUUuICBUaGUgYXZhaWxhYmxlIG9wdGlvbnMgZGVwZW5kIG9uIHRoZSBkaWZmZXJlbnQKIyBhdXRoZW50aWNhdGlvbiBtZXRob2RzIC0tIHJlZmVyIHRvIHRoZSAiQ2xpZW50IEF1dGhlbnRpY2F0aW9uIgojIHNlY3Rpb24gaW4gdGhlIGRvY3VtZW50YXRpb24gZm9yIGEgbGlzdCBvZiB3aGljaCBvcHRpb25zIGFyZQojIGF2YWlsYWJsZSBmb3Igd2hpY2ggYXV0aGVudGljYXRpb24gbWV0aG9kcy4KIwojIERhdGFiYXNlIGFuZCB1c2VyIG5hbWVzIGNvbnRhaW5pbmcgc3BhY2VzLCBjb21tYXMsIHF1b3RlcyBhbmQgb3RoZXIKIyBzcGVjaWFsIGNoYXJhY3RlcnMgbXVzdCBiZSBxdW90ZWQuICBRdW90aW5nIG9uZSBvZiB0aGUga2V5d29yZHMKIyAiYWxsIiwgInNhbWV1c2VyIiwgInNhbWVyb2xlIiBvciAicmVwbGljYXRpb24iIG1ha2VzIHRoZSBuYW1lIGxvc2UKIyBpdHMgc3BlY2lhbCBjaGFyYWN0ZXIsIGFuZCBqdXN0IG1hdGNoIGEgZGF0YWJhc2Ugb3IgdXNlcm5hbWUgd2l0aAojIHRoYXQgbmFtZS4KIwojIFRoaXMgZmlsZSBpcyByZWFkIG9uIHNlcnZlciBzdGFydHVwIGFuZCB3aGVuIHRoZSBzZXJ2ZXIgcmVjZWl2ZXMgYQojIFNJR0hVUCBzaWduYWwuICBJZiB5b3UgZWRpdCB0aGUgZmlsZSBvbiBhIHJ1bm5pbmcgc3lzdGVtLCB5b3UgaGF2ZSB0bwojIFNJR0hVUCB0aGUgc2VydmVyIGZvciB0aGUgY2hhbmdlcyB0byB0YWtlIGVmZmVjdCwgcnVuICJwZ19jdGwgcmVsb2FkIiwKIyBvciBleGVjdXRlICJTRUxFQ1QgcGdfcmVsb2FkX2NvbmYoKSIuCiMKIyBQdXQgeW91ciBhY3R1YWwgY29uZmlndXJhdGlvbiBoZXJlCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojCiMgSWYgeW91IHdhbnQgdG8gYWxsb3cgbm9uLWxvY2FsIGNvbm5lY3Rpb25zLCB5b3UgbmVlZCB0byBhZGQgbW9yZQojICJob3N0IiByZWNvcmRzLiAgSW4gdGhhdCBjYXNlIHlvdSB3aWxsIGFsc28gbmVlZCB0byBtYWtlIFBvc3RncmVTUUwKIyBsaXN0ZW4gb24gYSBub24tbG9jYWwgaW50ZXJmYWNlIHZpYSB0aGUgbGlzdGVuX2FkZHJlc3NlcwojIGNvbmZpZ3VyYXRpb24gcGFyYW1ldGVyLCBvciB2aWEgdGhlIC1pIG9yIC1oIGNvbW1hbmQgbGluZSBzd2l0Y2hlcy4KCiMgVFlQRSAgREFUQUJBU0UgICAgICAgIFVTRVIgICAgICAgICAgICBBRERSRVNTICAgICAgICAgICAgICAgICBNRVRIT0QKIyAibG9jYWwiIGlzIGZvciBVbml4IGRvbWFpbiBzb2NrZXQgY29ubmVjdGlvbnMgb25seS4KIyBEb27igJl0IGFsbG93IGFueSB1bml4IHNvY2tldCBjb25uZWN0aW9ucyBhcyB0aGUgYWxsb3lkYmFkbWluLgpsb2NhbCAgIGFsbCAgICAgICAgICAgICBhbGxveWRiYWRtaW4gICAgICAgICAgICAgICAgICAgICAgICAgICByZWplY3QKbG9jYWwgICBhbGwgICAgICAgICAgICAgYWxsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1kNQojIElQdjQgbG9jYWwgY29ubmVjdGlvbnM6Cmhvc3QgICAgYWxsICAgICAgICAgICAgIGFsbCAgICAgICAgICAgICAxMjcuMC4wLjEvMzIgICAgICAgICAgICB0cnVzdApob3N0ICAgIGFsbCAgICAgICAgICAgICBhbGwgICAgICAgICAgICAgMC4wLjAuMC8wICAgICAgICAgICAgICAgbWQ1CiMgSVB2NiBsb2NhbCBjb25uZWN0aW9uczoKaG9zdCAgICBhbGwgICAgICAgICAgICAgYWxsICAgICAgICAgICAgIDo6MS8xMjggICAgICAgICAgICAgICAgIHRydXN0CiMgQWxsb3cgcmVwbGljYXRpb24gY29ubmVjdGlvbnMgb24gbG9jYWxob3N0LCBmcm9tIGEgdXNlciB3aXRoIHRoZSByZXBsaWNhdGlvbiBwcml2aWxlZ2UuCmxvY2FsICAgcmVwbGljYXRpb24gICAgIGFsbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtZDUKaG9zdCAgICByZXBsaWNhdGlvbiAgICAgYWxsICAgICAgICAgICAgIDEyNy4wLjAuMS8zMiAgICAgICAgICAgIHRydXN0Cmhvc3QgICAgcmVwbGljYXRpb24gICAgIGFsbCAgICAgICAgICAgICA6OjEvMTI4ICAgICAgICAgICAgICAgICB0cnVzdA==" | base64 -d | sudo tee -a /var/alloydb/config/pg_hba.conf

# Copy our vesion of postgresql.conf. See postgresql.conf for details.
echo "IyBSZWZlcmVuY2UgcG9zdGdyZXMgY29uZmlndXJhdGlvbiBmb3IgQWxsb3lEQiBPbW5pCgphcmNoaXZlX2NvbW1hbmQ9Jy9iaW4vdHJ1ZScKYXJjaGl2ZV9tb2RlPW9mZgphcmNoaXZlX3RpbWVvdXQ9MzAwCmJnd3JpdGVyX2RlbGF5PTUwCmJnd3JpdGVyX2xydV9tYXhwYWdlcz0yMDAKY2hlY2twb2ludF9jb21wbGV0aW9uX3RhcmdldD0wLjkKZGF0ZXN0eWxlPSdpc28sIG1keScKZGVmYXVsdF90ZXh0X3NlYXJjaF9jb25maWc9J3BnX2NhdGFsb2cuZW5nbGlzaCcKZHluYW1pY19zaGFyZWRfbWVtb3J5X3R5cGU9cG9zaXgKaG90X3N0YW5kYnk9b24KaG90X3N0YW5kYnlfZmVlZGJhY2s9b24KaHVnZV9wYWdlcz1vbgpsY19tZXNzYWdlcz0nZW5fVVMuVVRGOCcKbGNfbW9uZXRhcnk9J2VuX1VTLlVURjgnCmxjX251bWVyaWM9J2VuX1VTLlVURjgnCmxjX3RpbWU9J2VuX1VTLlVURjgnCmxpc3Rlbl9hZGRyZXNzZXMgPSAnKicKbG9nX2F1dG92YWN1dW1fbWluX2R1cmF0aW9uPTAKbG9nX2RpcmVjdG9yeT0nbG9nJwpsb2dfZmlsZW5hbWU9J3Bvc3RncmVzJwpsb2dfbGluZV9wcmVmaXg9JyVtIFslcF06IFslbC0xXSBkYj0lZCx1c2VyPSV1ICcKbG9nX3JvdGF0aW9uX2FnZT0wCmxvZ19yb3RhdGlvbl9zaXplPTAKbG9nX3RlbXBfZmlsZXM9MApsb2dfdGltZXpvbmU9J1VUQycKbG9nZ2luZ19jb2xsZWN0b3I9J29uJwptYXhfY29ubmVjdGlvbnM9MTAwMAptYXhfbG9ja3NfcGVyX3RyYW5zYWN0aW9uPTY0Cm1heF9wcmVwYXJlZF90cmFuc2FjdGlvbnM9MAptYXhfcmVwbGljYXRpb25fc2xvdHM9NTAKbWF4X3dhbF9zZW5kZXJzPTUwCm1heF93YWxfc2l6ZT0xNTA0TUIKbWF4X3dvcmtlcl9wcm9jZXNzZXM9NjQKc2hhcmVkX2J1ZmZlcnNfYWN0aXZlX3JhdGlvPTAuNjUKc2hhcmVkX3ByZWxvYWRfbGlicmFyaWVzPSdnb29nbGVfY29sdW1uYXJfZW5naW5lLGdvb2dsZV9qb2Jfc2NoZWR1bGVyLGdvb2dsZV9kYl9hZHZpc29yLGdvb2dsZV9zdG9yYWdlLHBnX3N0YXRfc3RhdGVtZW50cycKc3luY2hyb25vdXNfY29tbWl0PW9uCnRpbWV6b25lPSdVVEMnCndhbF9pbml0X3plcm89b2ZmCndhbF9sZXZlbD1yZXBsaWNh" | base64 -d | sudo tee -a /var/alloydb/config/postgresql.conf

#Restart
sudo systemctl restart alloydb-dataplane
sudo systemctl status alloydb-dataplane

echo "Sleeping 10 seconds"
sleep 10

# Setup tables
ALLOYDB_PRIMARY_IP=127.0.0.1
MYAPP_USER=${env2_alloydb_myapp_user}
MYAPP_USER_PWD=${env2_alloydb_myapp_pwd}
psql -h $${ALLOYDB_PRIMARY_IP} -U postgres -c "CREATE USER $${MYAPP_USER} WITH LOGIN ENCRYPTED PASSWORD '"$${MYAPP_USER_PWD}"'"
psql -h $${ALLOYDB_PRIMARY_IP}  -U postgres -c "ALTER USER $${MYAPP_USER} CREATEDB"
export PGPASSWORD=$${MYAPP_USER_PWD}
psql -h $${ALLOYDB_PRIMARY_IP} -U myapp template1 -c "CREATE DATABASE imdb"
psql -h $${ALLOYDB_PRIMARY_IP} -U $${MYAPP_USER} imdb -c "CREATE TABLE title_basics(tconst varchar(12), title_type varchar(80), primary_title varchar(512), original_title varchar(512), is_adult boolean,start_year smallint, end_year smallint, runtime_minutes int, genres varchar(80))"


mkdir -p /home/ubuntu/tmp
cd /home/ubuntu/tmp && gsutil cp gs://gcp-mc-demo/myapp/title.basics.tsv.gz .
gzip -d title.basics.tsv.gz
psql -h $${ALLOYDB_PRIMARY_IP} -U $${MYAPP_USER} imdb -c "\copy title_basics FROM '/home/ubuntu/tmp/title.basics.tsv'"
