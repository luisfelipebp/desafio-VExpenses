
# Descrição técnica do arquivo Terraform

## Análise Técnica do Código Terraform

### Objetivo: 
Realizar a descrição técnica do arquivo Terraform desenvolvido para provisionar uma infraestrutura completa na AWS, utilizando recursos de rede, instâncias EC2, e outros componentes principais, como VPC, Subnets, Security Groups, e Key Pairs. Além disso,  implementar melhorias e modificações no arquivo a fim de gerar mais segurança, organização e legibilidade.

## Componentes

### Provedor: 
O código abaixo define o provedor AWS e configura a região onde os recursos serão implementados. O atributo region especifica que a infraestrutura será implementada na região us-east-1.

```
provider "aws" {
  region = "us-east-1"
}
```

- provider "aws": Define o provedor da infraestrutura como a plataforma de nuvem AWS.
- region "us-east-1": Define a região us-east-1 como o local onde os recursos da infraestrutura serão criados.

### VPC: 
O código a seguir cria a Virtual Private Cloud (VPC) que será utilizada na infraestrutura, juntamente com seus componentes, como sub-rede, Internet Gateway, tabela de rotas, entre outros.

#### Definição da VPC:
A VPC foi configurada com o bloco CIDR 10.0.0.0/16, onde os dois primeiros octetos são reservados para a rede e os dois últimos para os hosts. Além disso, o suporte para DNS e hostnames foram habilitados.

```
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}
```

- resource "aws_vpc" "main_vpc": Define o recurso como uma VPC da AWS, identificada como main_vpc.
- cidr_block: Define o bloco CIDR da rede como 10.0.0.0/16.
- enable_dns_support: Habilita o suporte para DNS.
- enable_dns_hostnames: Habilita o uso de hostnames DNS dentro da VPC.
- tags: Define as tags associadas a VPC, incluindo um nome formatado com as variáveis de projeto e candidato.

#### Criação da Sub-rede:

A sub-rede foi criada dentro da VPC, utilizando o bloco CIDR 10.0.1.0/24, onde os três primeiros octetos são reservados para a rede e o último para os hosts. A sub-rede foi atribuída à zona de disponibilidade us-east-1a.

``` 
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}
```

- resource "aws_subnet" "main_subnet": Define o recurso como uma sub-rede da AWS, identificada como main_subnet.
- vpc_id: A sub-rede é associada à VPC através do ID da VPC.
- cidr_block: Define o bloco CIDR da sub-rede como 10.0.1.0/24.
- availability_zone: Especifica a zona de disponibilidade da sub-rede, us-east-1a.
- tags: Define as tags associadas à sub-rede, incluindo um nome formatado com as variáveis de projeto e candidato.

### Internet Gateway

Foi criado o Internet Gateway para permitir a comunicação entre os recursos da VPC e a internet.

```
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}
```

- resource "aws_internet_gateway" "main_igw": Define o recurso como um Internet Gateway da AWS, identificado como main_igw.
- vpc_id: Define o id do vpc associado ao internet gateway.
- tags: Define as tags associadas à internet gateway, incluindo um nome formatado com as variáveis de projeto e candidato.

Obs: Para garantir maior disponibilidade do projeto, recomenda-se a criação de múltiplas sub-redes em diferentes zonas de disponibilidade. Dessa forma, caso ocorra algum problema em uma região, as outras poderão ser utilizadas para manter a operação.


### Tabela de rotas

A tabela de rotas define as regras de roteamento dentro da VPC. O tráfego com destino a qualquer IP (0.0.0.0/0) será roteado através do Internet Gateway, permitindo a comunicação com a internet.

```
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}
```

- resource "aws_route_table" "main_route_table": Define o recurso como uma tabela de rotas da AWS, identificada como main_route_table.
- route: Define uma rota onde todo o tráfego (0.0.0.0/0) é direcionado ao Internet Gateway (main_igw).
- tags: Define as tags associadas à route table, incluindo um nome formatado com as variáveis de projeto e candidato.

### Associação da Tabela de Rotas:

A tabela de rotas é associada à sub-rede, garantindo que as regras de roteamento sejam aplicadas à sub-rede criada.

```
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}

```

- resource "aws_route_table_association" "main_association": Define o recurso como uma associação entre a tabela de rotas e a sub-rede, identificada como main_association.
- subnet_id: ID da sub-rede associada.
- route_table_id: ID da tabela de rotas associada.
- tags: Define as tags associadas à route table associaton, incluindo um nome formatado com as variáveis de projeto e candidato.

### Security Group

O código a seguir define o grupo de segurança da infraestrutura, com configurações que controlam o tráfego de entrada e saída da instância. Este grupo de segurança permite que qualquer IP realize o SSH de qualquer lugar e também possibilita que a instância se conecte a qualquer lugar na internet ou rede, utilizando qualquer porta ou protocolo.

#### Definição do Security Group:

```
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }

  # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


```

- resource "aws_security_group" "main_sg": Define o tipo de recurso como um grupo de segurança da AWS, atribuindo o nome main_sg para identificação.
- name: Nome do Security Group
- description: Descrição do Security Group.
- vpc_id: Define a VPC onde o Security Group será criado.
- tags: Define as tags associadas ao security group, incluindo um nome formatado com as variáveis de projeto e candidato.

#### Regras:

- ingress: Define as regras de entrada do Security Group.
- egress: Define as regras de saída do Security Group.
- description: Descrição das regras de entrada e saída.
- from_port: Define o início do intervalo de portas dos protocolos TCP e UDP
- to_port: Define o final do intervalo de portas dos protocolos TCP e UDP.
- protocol: Define o tipo de protocolo.
- cidr_blocks: Define o conjunto de blocos CIDR de IPv4 que podem realizar as conexões definidas.
- ipv6_cidr_blocks: Define o conjunto de blocos CIDR de IPv6 que podem realizar as conexões definidas.

Obs: Neste caso, foi definido que qualquer IPv4 ou IPv6 pode realizar conexão via SSH. Deve ser evitado em projetos reais permitir que qualquer IP se conecte ao SSH, pois isso representa uma falha de segurança.

### Key Pairs: 

O código a seguir define a criação de um conjunto de credenciais que permite a conexão com a instância EC2. Foi utilizado o algoritmo RSA para gerar a chave privada, com um tamanho de 2048 bits.

```
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

```

- resource "tls_private_key" "ec2_key": Define o tipo de recurso como uma chave privada TLS e atribui o nome ec2_key para identificação.
- algorithm: Define o tipo de algoritmo utilizado na geração da chave.
- rsa_bits: Especifica o tamanho da chave RSA gerada em bits.

```
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

```
- resource "aws_key_pair" "ec2_key_pair": Cria um recurso do tipo AWS Key Pair, identificado como ec2_key_pair, usado para controlar o login de acesso das instâncias EC2.
- key_name: Define o nome do key pair, formatado com as variáveis de projeto e candidato.
- public_key: Define a chave pública do key pair, que é gerada a partir do recurso criado anteriormente (tls_private_key).


### Varíaveis:

A definição das variáveis utilizadas no código é fundamental para a personalização e reutilização. Neste exemplo, foram definidas inicialmente as variáveis projeto e candidato. O uso de variáveis garante segurança e reutilização do código.

```
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}

```

- variable "projeto": Define o nome da variável.
- description: Fornece uma breve descrição da variável.
- type: Define o tipo da variável.
- default: Especifica o valor padrão da variável.

Obs: As variaveis também podem ser acessadas diretamente utilizando apenas o prefixo var.nome_da_variavel.
 Por exemplo, para utilizar a variável "projeto", pode-se utilizar var.projeto.
 Podem ser criadas variáveis para configurar o projeto. Por exemplo, ao definir uma variável para a região, é possível alterar a configuração do projeto simplesmente modificando o valor dessa variável quando necessário.

 ### Instância:

 O código a seguir define a criação de uma instância EC2 da AWS, configurando uma máquina virtual com o sistema operacional Debian e suas devidas configurações de armazenamento e CPU.

### Componentes:

#### Data:

O código a seguir define a fonte de dados para obter a imagem mais recente do sistema operacional Debian 12:

``` 
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["679593333241"]
}
```
- data “aws_ami” “debian12” - Cria uma fonte de dados do tipo AWS AMI, identificada como debian 12
- most recent: Define que a imagem mais atual será utilizada.
- filter { name }: Define a chave a ser filtrada
- filter { values }: Define o valor a ser filtrado relacionado à chave.
- owners: Define o ID da conta AWS a ser buscada, garantindo que estamos acessando imagens de um proprietário específico.

#### Instância EC2

O código a seguir define a criação de uma instância EC2, utilizando a imagem do sistema operacional Debian 12 e o tipo de instância t2.micro, que fornece 1 vCPU e 1 GB de RAM. Foi definida a sub-rede onde a instância será implementada, o nome do key pair que será utilizado para acessar a instância via SSH, e o security group previamente criado. Além disso, um IP público foi associado à instância, possibilitando acesso pela Internet. Por fim, um shell script foi executado ao iniciar a instância pela primeira vez, que atualiza os dados, instala o Nginx, o inicia e configura para que o serviço inicie sempre que a instância for iniciada.

```
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

```
- resource "aws_instance" "debian_ec2": Define a instância EC2 a ser criada, identificada como debian_ec2.
- ami: Define a imagem do sistema operacional utilizado (Debian 12).
- instance_type: Define o tipo de configurações utilizados na instância
- subnet_id: Referencia o ID da sub-rede onde a instância será implementada.
- key_name: Referencia o nome do key pair criado anteriormente para acesso via SSH.
- security_groups: Referencia a lista de grupos de segurança que será utilizada para controlar o tráfego da instância.
- associate_public_ip_address: Associa um IP público à instância, permitindo acesso pela Internet.
#
- root_block_device: Define as propriedades do dispositivo de bloco, utilizando a ferramenta EBS, que serve como disco rígido da instância EC2:
- root_block_device {volume_size}: Define o tamanho do volume do dispositivo de bloco raiz.
- root_block_device {volume_type}: Define o tipo de volume usado.
- root_block_device {delete_on_termination}: Define que o volume deve ser excluído ao encerrar a instância.
#
- user_data: Define os comandos que serão executados automaticamente quando a instância for iniciada pela primeira vez:
``` 
apt-get update (Atualiza o sistema)
apt-get upgrade (Atualiza os pacotes instalados)
apt-get install -y nginx (Instala o Nginx)
systemctl start nginx (Inicia o serviço do Nginx)
systemctl enable nginx (Configura o Nginx para iniciar automaticamente em futuras inicializações)

```
- tags: Define as tags associadas à instância, incluindo um nome formatado com as variáveis de projeto e candidato.

### Output

O código a seguir define duas saídas que serão exibidas na linha de comando quando o arquivo Terraform for iniciado. Essas saídas mostram a chave privada para acessar a instância EC2 e o endereço IP da instância EC2.

```

output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}

```

- output “private_key” - Define a saída que será exibida
- description - Descrição do valor que será mostrado na saída.
- value =  O valor que será mostrado na saída
- sensitive = Define que este é um dado sensível 

# 
## Modificação e Melhoria do Código Terraform

### Módulos

Para aprimorar a organização e a legibilidade do código, dividi o projeto em vários módulos, cada um com uma função específica:

- Módulo VPC: Responsável pela criação e configuração da Virtual Private Cloud (VPC).
- Módulo Vars: Contém todas as variáveis necessárias para a configuração do projeto, facilitando a reutilização e a manutenção do código.
- Módulo Security Group: Define as regras de segurança para controlar o tráfego de entrada e saída dos recursos.
- Módulo Provider: Configura o provedor AWS e suas respectivas regiões.
- Módulo Key Pairs: Gerencia a criação e a configuração das chaves de acesso para instâncias EC2.


### Variáveis: 
Além disso, criei variáveis específicas para a região e a zona, o que permite uma configuração mais flexível e simplificada, facilitando futuras alterações nas configurações de rede e infraestrutura.

#### Variável para região: 

```
variable "regiao" {
  default = "us-east-1"
}

```

#### Variável para zona: 
```
variable "zona" {
  default = "us-east-1a"
}
```
### Segurança:

Criação da variável para o IP público fornecido pela instância EC2:

```
variable "meuIp" {
  default = "192.168.1.100/32" 
}

```
Obs: O IP será diferente para cada usuário; a variável deve ser ajustada em caso de testes.

Foi configurado para permitir que apenas o IP determinado (neste caso, o seu IP) possa realizar uma conexão SSH para a instância. Além disso, foi removido o acesso de qualquer endereço IPv6.

```
 # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${var.meuIp}"]
  }

  ```

Foi criado um segredo no Secrets Manager para armazenar a chave privada e removido o output para evitar a exposição da chave.

```
resource "aws_secretsmanager_secret" "ec2_key_secret" {
  name = "${var.projeto}-${var.candidato}-ec2-key-secret"
}

resource "aws_secretsmanager_secret_version" "ec2_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.ec2_key_secret.id
  secret_string = tls_private_key.ec2_key.private_key_pem
}

```
Remoção do trecho de código do módulo main.tf:

```
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}


```


### Correções:
Removido o atributo "tags" do recurso "aws_route_table_association", pois ele não é compatível com esse argumento, o que gerava um erro ao executar o comando terraform validate.

#

# Instruções de uso:

## Pré-configuração: 

- Após a instalação do AWS CLI, é necessário configurá-lo para que ele possa acessar sua conta da AWS. Isso é feito através do comando aws configure.

- Abra o terminal e execute o comando que solicitará suas credenciais de acesso e a região padrão da aws:

```
aws configure
```

Esse comando solicitará suas credenciais de acesso e a região padrão.

## Configuração para Terraform

-  No diretório onde estão localizados os arquivos Terraform (.tf), você deve seguir os seguintes passos para configurar e executar sua infraestrutura:

```
terraform init
```

Ele verifica o provedor especificado no código, baixa os plugins necessários e realiza as verificações necessárias no diretório atual.
Um arquivo oculto é gerado, contendo as informações dos plugins necessários.

```
terraform validate
```

Este comando verifica se há erros de sintaxe no código Terraform.
Ele garante que a configuração está correta antes de prosseguir para a aplicação dos recursos.

```
terraform fmt
```

Este comando formata o código Terraform de acordo com as melhores práticas de formatação.
Ele alinha e torna o código mais legível, facilitando a manutenção e a colaboração.

```
terraform plan
```

Este comando exibe um plano de execução, mostrando o que será realizado caso você execute o comando apply.
Ele detalha quais recursos serão adicionados, removidos ou alterados, permitindo revisar as mudanças antes da aplicação.

```
terraform apply
```

Este comando aplica as configurações definidas nos arquivos Terraform.
Ele cria os recursos conforme especificado, com base no plano gerado anteriormente.
