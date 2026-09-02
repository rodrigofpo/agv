# agv

`agv` é um gerenciador simples para as três formas de distribuição do Google
Antigravity no Linux: IDE, CLI `agy` e SDK Python. O projeto também contorna o
fato de os repositórios RPM e APT oficiais permanecerem na build legada
`1.23.2`, gerando um pacote atualizado da IDE por meio do `packaged-gravity`.

## Instalação

Clone o repositório e execute o instalador local:

```bash
git clone https://github.com/rodrigofpo/agv.git
cd agv
./install.sh
```

Também é possível baixar os arquivos `agv-0.1.0.tar.gz` e
`agv-0.1.0.tar.gz.sha256` da seção **Releases**, validar o pacote, extrair e
executar o instalador:

```bash
sha256sum -c agv-0.1.0.tar.gz.sha256
tar -xzf agv-0.1.0.tar.gz
cd agv-0.1.0
./install.sh
```

O instalador copia o projeto para `~/.local/share/agv` e cria o comando
`~/.local/bin/agv`. Caso esse diretório não esteja no `PATH`, siga a orientação
exibida ao final da instalação.

## Uso

| Comando | Descrição |
| --- | --- |
| `agv install <produto>` | Instala um produto |
| `agv update <produto>` | Atualiza um produto |
| `agv status [produto]` | Mostra o status de um produto ou de todos |
| `agv uninstall <produto>` | Desinstala um produto |
| `agv list` | Lista os produtos disponíveis |
| `agv help` | Mostra a ajuda |
| `agv version` | Mostra a versão instalada |

Os produtos incluídos são `ide`, `cli` e `sdk`. Exemplos:

```bash
agv install ide
agv update cli
agv status sdk
agv status
agv remove-legacy ide
```

O SDK é instalado com `pip install --user`, sem virtualenv, para manter o fluxo
simples. Quem preferir isolamento pode instalar e gerenciar
`google-antigravity` manualmente com `pip` dentro de um virtualenv ativado. Para
usar o SDK, também é necessário definir a variável `GEMINI_API_KEY`.

## Arquitetura de plugins

Cada arquivo `plugins/<produto>.sh` registra seu produto:

```bash
register_plugin exemplo "Descrição do produto"
```

O contrato padrão é composto por quatro funções:

```bash
exemplo_install
exemplo_update
exemplo_status
exemplo_uninstall
```

O entrypoint monta dinamicamente o nome da função a partir do produto e da
ação. Uma ação sem produto é executada em todos os plugins que a implementam.
Verbos adicionais também são permitidos: hífens na linha de comando são
convertidos em sublinhados no nome da função, portanto `remove-legacy` resolve
`<produto>_remove_legacy`.

## Como escrever um plugin novo

1. Crie `plugins/<nome>.sh`.
2. Chame `register_plugin <nome> "<descrição>"` no topo do arquivo.
3. Implemente `<nome>_install`, `<nome>_update`, `<nome>_status` e
   `<nome>_uninstall`.
4. Valide a sintaxe com `bash -n plugins/<nome>.sh`.
5. Teste o registro e o status com `agv status <nome>`.

Funções auxiliares específicas do plugin devem usar um prefixo próprio, como
`_nome_`, para evitar colisões com outros plugins.

## Créditos

O plugin `ide` usa o projeto
[packaged-gravity](https://github.com/vittico/packaged-gravity), distribuído sob
a licença MIT, para gerar pacotes RPM e DEB da IDE.

## Licença

Distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
