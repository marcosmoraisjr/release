# release

Feed público de atualização automática (Velopack) das ferramentas de Marcos Morais.

Aqui ficam **apenas instaladores e pacotes de atualização** — nenhum código-fonte do produto.
Cada produto tem uma Release fixa (tag minúscula, ex.: `mywallpapers`) com todos os pacotes e o índice `releases.win.json`.

## Espelho (release.autvs.com)

`Dockerfile`, `nginx.conf`, `sync.sh` e `entrypoint.sh` montam um espelho: um nginx que serve os mesmos arquivos
das Releases e **puxa do GitHub a cada 5 minutos** (pacotes primeiro, índices por último; remove o que saiu da Release).
O aplicativo tenta o GitHub e, se falhar, o espelho (`https://release.autvs.com/<produto>/`).

### Publicar no Coolify
1. **DNS:** registro `A` de `release.autvs.com` para o IP do servidor do Coolify.
2. **Novo recurso → Public Repository** → `https://github.com/marcosmoraisjr/release`, branch `main`, *Build Pack:* **Dockerfile**.
3. **Domains:** `https://release.autvs.com` · **Port:** `80`.
4. **Persistent Storage:** volume montado em `/data` (os arquivos sobrevivem a redeploys).
5. Variáveis (opcionais): `SYNC_INTERVAL` (segundos, padrão 300) e `REPO` (padrão `marcosmoraisjr/release`).
6. **Deploy.** Teste: `https://release.autvs.com/health` → `ok`; depois de alguns minutos,
   `https://release.autvs.com/mywallpapers/releases.win.json`.
