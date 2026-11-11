#

## Instalação

Na primeira instalação, com preenchimento interativo:

````bash
curl -fsSL \
  https://raw.githubusercontent.com/HGSM-Dr-Manoel-Bifulco/hgsm_ghapp/refs/heads/main/install-github-app.sh \
  | sudo bash
````

Ou informando os IDs diretamente:

````bash
curl -fsSL \
  https://raw.githubusercontent.com/HGSM-Dr-Manoel-Bifulco/hgsm_ghapp/refs/heads/main/install-github-app.sh \
  | sudo bash -s -- APP_ID INSTALLATION_ID
````

Se ambos forem deixados em branco, será criada uma cópia de config.example como config.

## Depois da instalação

### Inserindo a Chave

Copie o PEM para o caminho informado pelo instalador:

````bash
sudo cp sua-chave-privada.pem /etc/github-app/private-key.pem
sudo chown root:root /etc/github-app/private-key.pem
sudo chmod 600 /etc/github-app/private-key.pem
````

### Teste da autenticação

````bash
sudo /etc/github-app/github-auth HGSM-Dr-Manoel-Bifulco/HGSM-noc
````

O comando retornará o token. Como ele é um segredo temporário, evite deixá-lo registrado no histórico ou em logs.

### Teste de pull

````bash
sudo github-pull HGSM-Dr-Manoel-Bifulco/[repositorio] [local/de/instalação]
````

Uma observação de segurança: o instalador preserva o config existente, mas atualiza os executáveis quando executado novamente. Isso permite atualizar os scripts sem apagar a configuração e a chave privada já instaladas.
