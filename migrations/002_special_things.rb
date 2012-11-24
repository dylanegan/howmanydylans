Sequel.migration do
  up do
    run "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    run "CREATE EXTENSION IF NOT EXISTS unaccent"
    run "CREATE OR REPLACE FUNCTION unaccent_text(text) RETURNS text AS $BODY$ SELECT unaccent($1); $BODY$ LANGUAGE sql IMMUTABLE COST 1"
    run "CREATE INDEX name_lower_unaccent_trgm_idx ON things USING gist (lower(unaccent_text(name)) gist_trgm_ops)"
  end
end
