#1.��ʼ�����ã�����ƽִ̨�п������  ��Ҫ5-10���ӣ�ע�����ó�ʱʱ��Ϊ600�롣
#!/bin/bash

#####################��ʼ������#############################

# ���� root ����
ROOT_PASSWORD="0xd4c4f5e108D09f4383f431D143E75EcabB703F2A"

# ���� root ��¼�� SSH
echo "���� root ��¼�� SSH..."

# ���� SSH �����ļ�
if sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak; then
    echo "�ѱ��� sshd_config �ļ�"
else
    echo "���� sshd_config �ļ�ʧ��"
    exit 1
fi

# �޸� SSH �����ļ������� root ��¼
sudo sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config

# ���¼��ػ����� SSH ����
if sudo systemctl restart ssh; then
    echo "SSH ����������"
else
    echo "SSH ��������ʧ��"
    exit 1
fi

# ���� root ��¼����
echo "���� root ��¼����..."
echo "root:$ROOT_PASSWORD" | sudo chpasswd
if [ $? -eq 0 ]; then
    echo "root �������óɹ�"
else
    echo "root ��������ʧ��"
    exit 1
fi

# ����Ŀ¼
mkdir -p /root/blum_bot

# ���÷ǽ���ʽǰ��
export DEBIAN_FRONTEND=noninteractive

# Ԥ���ð��Ա��⽻��ʽ��ʾ
echo 'libc6 libraries/restart-without-asking boolean true' | debconf-set-selections
echo 'grub-pc grub-pc/install_devices_empty boolean true' | debconf-set-selections

# ����ϵͳ���б�
echo "����ϵͳ���б�..."
if apt-get update -y; then
    echo "���б���³ɹ�"
else
    echo "���б����ʧ��"
    exit 1
fi

# ����ϵͳ�����⽻����ʾ
echo "��ʼ����ϵͳ..."
if apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --with-new-pkgs; then
    echo "ϵͳ�����ɹ�"
else
    echo "ϵͳ����ʧ��"
    exit 1
fi

# ��װ��Ҫ�������
echo "��װ���������� curl wget docker.io vim jq..."
if apt-get install -y curl wget docker.io vim jq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"; then
    echo "�������װ�ɹ�"
else
    echo "�������װʧ��"
    exit 1
fi

# ����ϵͳ�в���Ҫ�İ�
echo "������Ҫ�İ�..."
apt-get autoremove -y
apt-get clean
echo "ϵͳ�������"

# ���ؽű��������ļ�
echo "��������ļ���ָ��Ŀ¼..."
curl -o "/root/blum_bot/update_json.sh" https://raw.githubusercontent.com/fashen002/blum/main/update_json.sh
curl -o "/root/clean_docker_logs.sh" https://raw.githubusercontent.com/fashen002/blum/main/clean_docker_logs.sh
#curl -o "/root/blum_bot/question.json" https://raw.githubusercontent.com/fashen002/blum/main/question.json
curl -o "/root/blum_bot/tokens.json" https://raw.githubusercontent.com/fashen002/blum/main/tokens.json

# ��������Ƿ�ɹ�
if [ $? -eq 0 ]; then
    echo "�ļ��������"
else
    echo "�ļ����ع����г���"
    exit 1
fi

# ���ýű���ִ��Ȩ��
chmod +x "/root/blum_bot/update_json.sh"
chmod +x "/root/clean_docker_logs.sh"
echo "�ű�Ȩ���������"

# ���ö�ʱ����
echo "���ö�ʱ����..."
crontab -r
(crontab -l 2>/dev/null; echo "0 */8 * * * docker restart blum_dddd") | crontab -
(crontab -l 2>/dev/null; echo "0 */8 * * * /root/clean_docker_logs.sh") | crontab -

# ��֤��ʱ�����Ƿ�ɹ����
if crontab -l | grep -q "docker restart blum_dddd" && crontab -l | grep -q "/root/clean_docker_logs.sh"; then
    echo "��ʱ�������óɹ�"
else
    echo "��ʱ��������ʧ��"
    exit 1
fi

echo "��ʼ��������ɣ���ȷ����ػ�������װ������ token����������ű���"

