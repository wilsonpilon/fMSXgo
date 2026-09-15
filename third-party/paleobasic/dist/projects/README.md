# projects/

Aqui vive `noname.msxproject`, o projeto padrão que o Paleobasic abre
automaticamente quando é iniciado sem nenhum projeto especificado
(`ProjectDB::NewTempPath()`, `src/editor/core/ProjectDB.pbi`). É criado na
primeira vez que o editor precisa dele — vazio, novo, sem conteúdo — e não é
versionado (é estado mutável de sessão, muda a cada uso; ver `.gitignore`).

Este arquivo `README.md` só existe para o diretório `projects/` sobreviver a
um `git clone` fresco (o git não versiona diretórios vazios).
