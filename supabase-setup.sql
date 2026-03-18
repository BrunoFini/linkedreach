-- LinkedReach — Setup do banco de dados
-- Rodar no Supabase: SQL Editor → New query → colar tudo → Run

-- Tabela de prospects
CREATE TABLE IF NOT EXISTS prospects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  cargo TEXT,
  funcao TEXT,
  empresa TEXT,
  cidade TEXT,
  estado TEXT,
  linkedin_url TEXT,
  foto_url TEXT,
  status TEXT DEFAULT 'pendente' CHECK (status IN ('pendente', 'enviado', 'respondido')),
  notas TEXT,
  mensagem_enviada TEXT,
  copiado_em TIMESTAMPTZ,
  enviado_em TIMESTAMPTZ,
  respondido_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de templates de mensagem
CREATE TABLE IF NOT EXISTS templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  corpo TEXT NOT NULL,
  favorito BOOLEAN DEFAULT FALSE,
  usos INTEGER DEFAULT 0,
  criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE prospects ENABLE ROW LEVEL SECURITY;
ALTER TABLE templates ENABLE ROW LEVEL SECURITY;

-- Políticas RLS — cada usuário vê apenas os próprios dados
CREATE POLICY "prospects_own" ON prospects FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "templates_own" ON templates FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Trigger para atualizar atualizado_em automaticamente
CREATE OR REPLACE FUNCTION update_atualizado_em()
RETURNS TRIGGER AS $$ BEGIN NEW.atualizado_em = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prospects_atualizado_em ON prospects;
CREATE TRIGGER prospects_atualizado_em
  BEFORE UPDATE ON prospects
  FOR EACH ROW EXECUTE FUNCTION update_atualizado_em();

-- Templates padrão (inseridos após login pelo app)
-- Os templates são inseridos pelo app no primeiro acesso
