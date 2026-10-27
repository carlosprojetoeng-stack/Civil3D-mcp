# Civil3D-MCP no Civil 3D 2027: passo a passo

Esta versão do projeto foi adaptada para o **Civil 3D 2027**, que usa **.NET 10** (a 2025 e a 2026 usavam .NET 8).
O projeto original só foi validado na 2026. Faça os primeiros testes **numa cópia de um desenho**.

## O que foi alterado em relação ao original

| Arquivo | Alteração |
|---|---|
| `Civil3D-MCP-Plugin/Civil3DMcpPlugin.csproj` | Alvo `net10.0-windows` (padrão). Para voltar à 2026, use `/p:Civil3DTargetFramework=net8.0-windows`. |
| `scripts/build-plugin-2027.ps1` (novo) | Localiza as DLLs da Autodesk na sua instalação, copia para `C_References\` e compila o plugin. |
| `scripts/install-claude-mcp.ps1` | Registra o servidor com `CIVIL3D_HELP_VERSION=2027` (parâmetro `-HelpVersion`). |
| `packaging/claude-desktop/manifest.json` | A versão de ajuda padrão passou a ser 2027. |

O código C# não foi alterado. O plugin já tem uma camada de compatibilidade por reflexão (`Civil3DCompatibility.cs`) para tolerar diferenças entre versões da API.

## 1. Instalar os pré-requisitos (uma vez só)

1. **Node.js 18 ou mais recente** (LTS): https://nodejs.org
2. **.NET SDK 10**: https://dotnet.microsoft.com/download/dotnet/10.0
3. **Visual Studio 2026** (opcional, mas recomendado pela Autodesk para a 2027), com a carga de trabalho "Desenvolvimento para desktop com .NET".
4. **Claude Code**: no PowerShell, `npm install -g @anthropic-ai/claude-code`, depois rode `claude` uma vez para fazer login.

Para conferir: `node -v`, `dotnet --list-sdks` (precisa aparecer uma linha `10.x`) e `claude --version`.

## 2. Compilar o servidor (Node)

Na pasta do projeto:

```powershell
npm install
npm run build
```

## 3. Compilar o plugin para a 2027

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-plugin-2027.ps1
```

Se o Civil 3D estiver instalado em outro caminho:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-plugin-2027.ps1 -AutoCADRoot "D:\Autodesk\AutoCAD 2027"
```

Ao final, aparece o caminho do `Civil3DMcpPlugin.dll`, que fica em `Civil3D-MCP-Plugin\bin\Release\net10.0-windows\`.

**Se der erro de compilação**, copie as mensagens de erro e envie para análise. Na 2027, a Autodesk removeu um membro da API .NET, então pode ser preciso um ajuste pontual.

## 4. Carregar o plugin no Civil 3D 2027

1. Abra o Civil 3D 2027 com um desenho (de preferência uma cópia).
2. Digite `NETLOAD` e selecione o `Civil3DMcpPlugin.dll`.
3. Digite `C3DMCPSTATUS`. O plugin deve informar que está escutando na porta 8080.

Para carregar automaticamente sempre que abrir o Civil 3D: `APPLOAD` → **Startup Suite** → **Contents** → adicione o DLL.

> Se o Civil 3D bloquear o DLL por segurança, adicione a pasta do plugin em `OPTIONS` → **Files** → **Trusted Locations**.

## 5. Ligar o Claude Code ao Civil 3D

Na pasta do projeto:

```powershell
npm run claude:add
```

Esse comando cria o `.mcp.json` do projeto. Para deixar disponível em qualquer pasta:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-claude-mcp.ps1 -Scope user
```

Se já houver um registro anterior, remova antes com `claude mcp remove civil3d-mcp -s project` (ou `-s user`).

## 6. Testar

Com o Civil 3D aberto e o plugin carregado, rode `claude` na pasta do projeto e peça:

1. "Rode o civil3d_health." Isso confirma a conexão.
2. "Mostre as informações do desenho atual."
3. "Liste as superfícies e alinhamentos com as propriedades principais."

Comece por consultas (só leitura). As operações que alteram o desenho ou gravam arquivos pedem aprovação antes de executar.

## Problemas comuns

| Sintoma | Causa provável |
|---|---|
| `civil3d_health` não conecta | O plugin não foi carregado (`NETLOAD`) ou a porta 8080 está ocupada ou bloqueada pelo firewall. |
| NETLOAD dá erro de versão do .NET | O DLL foi compilado para net8 em vez de net10. Recompile com o script do passo 3. |
| Uma ferramenta responde "not exposed by the managed API" | É uma limitação da API da Autodesk. O próprio projeto avisa e não altera nada. |
| Comando lento ou com timeout | Corredores pesados. Aumente `CIVIL3D_COMMAND_TIMEOUT` (em ms). |
