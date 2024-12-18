--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 17.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: _heroku; Type: SCHEMA; Schema: -; Owner: heroku_admin
--

CREATE SCHEMA _heroku;


ALTER SCHEMA _heroku OWNER TO heroku_admin;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: ubicja6nk7obgf
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO ubicja6nk7obgf;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: ubicja6nk7obgf
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: create_ext(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.create_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'CREATE EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

        schemaname = (
            SELECT n.nspname
            FROM pg_catalog.pg_extension AS e
            INNER JOIN pg_catalog.pg_namespace AS n
            ON e.extnamespace = n.oid
            WHERE e.oid = r.objid
        );

        databaseowner = (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = current_database()
        );
        --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, schema: %, database_owenr: %', r.object_identity, r.objid, tg_tag, current_user, schemaname, databaseowner;
        IF r.object_identity = 'address_standardizer_data_us' THEN
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_gaz');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_lex');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_rules');
        ELSIF r.object_identity = 'amcheck' THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.bt_index_check TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.bt_index_parent_check TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'dict_int' THEN
            EXECUTE format('ALTER TEXT SEARCH DICTIONARY %I.intdict OWNER TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'pg_partman' THEN
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'part_config');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'part_config_sub');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'custom_time_partitions');
        ELSIF r.object_identity = 'pg_stat_statements' THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.pg_stat_statements_reset TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'postgis' THEN
            PERFORM _heroku.postgis_after_create();
        ELSIF r.object_identity = 'postgis_raster' THEN
            PERFORM _heroku.postgis_after_create();
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT', databaseowner, 'raster_columns');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT', databaseowner, 'raster_overviews');
        ELSIF r.object_identity = 'postgis_topology' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT USAGE ON SCHEMA topology TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA topology TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('topology', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);
            EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA topology TO %I;', databaseowner);
        ELSIF r.object_identity = 'postgis_tiger_geocoder' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT USAGE ON SCHEMA tiger TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('tiger', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);

            EXECUTE format('GRANT USAGE ON SCHEMA tiger_data TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger_data TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('tiger_data', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);
        END IF;
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.create_ext() OWNER TO heroku_admin;

--
-- Name: drop_ext(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.drop_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'DROP EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
      CONTINUE WHEN r.object_type != 'extension';

      databaseowner = (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = current_database()
      );

      --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, database_owner: %, schemaname: %', r.object_identity, r.objid, tg_tag, current_user, databaseowner, r.schema_name;

      IF r.object_identity = 'postgis_topology' THEN
          EXECUTE format('DROP SCHEMA IF EXISTS topology');
      END IF;
    END LOOP;

  END IF;
END;
$$;


ALTER FUNCTION _heroku.drop_ext() OWNER TO heroku_admin;

--
-- Name: extension_before_drop(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.extension_before_drop() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  query TEXT;

BEGIN
  query = (SELECT current_query());

  -- RAISE NOTICE 'executing extension_before_drop: tg_event: %, tg_tag: %, current_user: %, session_user: %, query: %', tg_event, tg_tag, current_user, session_user, query;
  IF tg_tag = 'DROP EXTENSION' and not pg_has_role(session_user, 'rds_superuser', 'MEMBER') THEN
    -- DROP EXTENSION [ IF EXISTS ] name [, ...] [ CASCADE | RESTRICT ]
    IF (regexp_match(query, 'DROP\s+EXTENSION\s+(IF\s+EXISTS)?.*(plpgsql)', 'i') IS NOT NULL) THEN
      RAISE EXCEPTION 'The plpgsql extension is required for database management and cannot be dropped.';
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.extension_before_drop() OWNER TO heroku_admin;

--
-- Name: grant_table_if_exists(text, text, text, text); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.grant_table_if_exists(alias_schemaname text, grants text, databaseowner text, alias_tablename text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

BEGIN

  IF alias_tablename IS NULL THEN
    EXECUTE format('GRANT %s ON ALL TABLES IN SCHEMA %I TO %I;', grants, alias_schemaname, databaseowner);
  ELSE
    IF EXISTS (SELECT 1 FROM pg_tables WHERE pg_tables.schemaname = alias_schemaname AND pg_tables.tablename = alias_tablename) THEN
      EXECUTE format('GRANT %s ON TABLE %I.%I TO %I;', grants, alias_schemaname, alias_tablename, databaseowner);
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.grant_table_if_exists(alias_schemaname text, grants text, databaseowner text, alias_tablename text) OWNER TO heroku_admin;

--
-- Name: postgis_after_create(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.postgis_after_create() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    schemaname TEXT;
    databaseowner TEXT;
BEGIN
    schemaname = (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n ON e.extnamespace = n.oid
        WHERE e.extname = 'postgis'
    );
    databaseowner = (
        SELECT pg_catalog.pg_get_userbyid(d.datdba)
        FROM pg_catalog.pg_database d
        WHERE d.datname = current_database()
    );

    EXECUTE format('GRANT EXECUTE ON FUNCTION %I.st_tileenvelope TO %I;', schemaname, databaseowner);
    EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.spatial_ref_sys TO %I;', schemaname, databaseowner);
END;
$$;


ALTER FUNCTION _heroku.postgis_after_create() OWNER TO heroku_admin;

--
-- Name: validate_extension(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.validate_extension() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  r RECORD;

BEGIN

  IF tg_tag = 'CREATE EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
      CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

      schemaname = (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n
        ON e.extnamespace = n.oid
        WHERE e.oid = r.objid
      );

      IF schemaname = '_heroku' THEN
        RAISE EXCEPTION 'Creating extensions in the _heroku schema is not allowed';
      END IF;
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.validate_extension() OWNER TO heroku_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO ubicja6nk7obgf;

--
-- Name: classe_persos; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.classe_persos (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.classe_persos OWNER TO ubicja6nk7obgf;

--
-- Name: classe_persos_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.classe_persos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classe_persos_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: classe_persos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.classe_persos_id_seq OWNED BY public.classe_persos.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.groups OWNER TO ubicja6nk7obgf;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.groups_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: holonews; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.holonews (
    id bigint NOT NULL,
    title character varying,
    content text,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    target_user integer,
    target_group character varying
);


ALTER TABLE public.holonews OWNER TO ubicja6nk7obgf;

--
-- Name: holonews_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.holonews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.holonews_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: holonews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.holonews_id_seq OWNED BY public.holonews.id;


--
-- Name: inventory_objects; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.inventory_objects (
    id bigint NOT NULL,
    name character varying,
    category character varying,
    description text,
    price integer,
    rarity character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.inventory_objects OWNER TO ubicja6nk7obgf;

--
-- Name: inventory_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.inventory_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_objects_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: inventory_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.inventory_objects_id_seq OWNED BY public.inventory_objects.id;


--
-- Name: pet_inventory_objects; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.pet_inventory_objects (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    inventory_object_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.pet_inventory_objects OWNER TO ubicja6nk7obgf;

--
-- Name: pet_inventory_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.pet_inventory_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pet_inventory_objects_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: pet_inventory_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.pet_inventory_objects_id_seq OWNED BY public.pet_inventory_objects.id;


--
-- Name: pets; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.pets (
    id bigint NOT NULL,
    name character varying,
    race character varying,
    hp_current integer,
    hp_max integer,
    res_corp integer,
    res_corp_bonus integer,
    speed double precision,
    damage_1 character varying,
    damage_2 character varying,
    accuracy double precision,
    dodge double precision,
    weapon_1 character varying,
    weapon_2 character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.pets OWNER TO ubicja6nk7obgf;

--
-- Name: pets_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pets_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: pets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.pets_id_seq OWNED BY public.pets.id;


--
-- Name: races; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.races (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.races OWNER TO ubicja6nk7obgf;

--
-- Name: races_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.races_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.races_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: races_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.races_id_seq OWNED BY public.races.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO ubicja6nk7obgf;

--
-- Name: skills; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.skills (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.skills OWNER TO ubicja6nk7obgf;

--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.skills_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.skills_id_seq OWNED BY public.skills.id;


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.statuses (
    id bigint NOT NULL,
    name character varying,
    description text,
    color character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.statuses OWNER TO ubicja6nk7obgf;

--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.statuses_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.statuses_id_seq OWNED BY public.statuses.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.transactions (
    id bigint NOT NULL,
    sender_id integer,
    receiver_id integer,
    amount integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.transactions OWNER TO ubicja6nk7obgf;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: user_inventory_objects; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.user_inventory_objects (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    inventory_object_id bigint NOT NULL,
    quantity integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_inventory_objects OWNER TO ubicja6nk7obgf;

--
-- Name: user_inventory_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.user_inventory_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_inventory_objects_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: user_inventory_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.user_inventory_objects_id_seq OWNED BY public.user_inventory_objects.id;


--
-- Name: user_skills; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.user_skills (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    skill_id bigint NOT NULL,
    mastery integer DEFAULT 0 NOT NULL,
    bonus integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_skills OWNER TO ubicja6nk7obgf;

--
-- Name: user_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.user_skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_skills_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: user_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.user_skills_id_seq OWNED BY public.user_skills.id;


--
-- Name: user_statuses; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.user_statuses (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    status_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_statuses OWNER TO ubicja6nk7obgf;

--
-- Name: user_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.user_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_statuses_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: user_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.user_statuses_id_seq OWNED BY public.user_statuses.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    credits integer DEFAULT 0,
    username character varying,
    group_id bigint NOT NULL,
    hp_max integer,
    hp_current integer,
    shield_state boolean,
    shield_max integer,
    shield_current integer,
    race_id bigint,
    classe_perso_id bigint,
    xp integer DEFAULT 0,
    total_xp integer DEFAULT 0,
    robustesse boolean DEFAULT false,
    homeopathie boolean DEFAULT false,
    patch integer,
    echani_shield_state boolean,
    echani_shield_current integer,
    echani_shield_max integer,
    luck boolean DEFAULT false,
    pet_id bigint
);


ALTER TABLE public.users OWNER TO ubicja6nk7obgf;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: ubicja6nk7obgf
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO ubicja6nk7obgf;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubicja6nk7obgf
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: classe_persos id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.classe_persos ALTER COLUMN id SET DEFAULT nextval('public.classe_persos_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: holonews id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.holonews ALTER COLUMN id SET DEFAULT nextval('public.holonews_id_seq'::regclass);


--
-- Name: inventory_objects id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.inventory_objects ALTER COLUMN id SET DEFAULT nextval('public.inventory_objects_id_seq'::regclass);


--
-- Name: pet_inventory_objects id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.pet_inventory_objects ALTER COLUMN id SET DEFAULT nextval('public.pet_inventory_objects_id_seq'::regclass);


--
-- Name: pets id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.pets ALTER COLUMN id SET DEFAULT nextval('public.pets_id_seq'::regclass);


--
-- Name: races id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.races ALTER COLUMN id SET DEFAULT nextval('public.races_id_seq'::regclass);


--
-- Name: skills id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.skills ALTER COLUMN id SET DEFAULT nextval('public.skills_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.statuses ALTER COLUMN id SET DEFAULT nextval('public.statuses_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: user_inventory_objects id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_inventory_objects ALTER COLUMN id SET DEFAULT nextval('public.user_inventory_objects_id_seq'::regclass);


--
-- Name: user_skills id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_skills ALTER COLUMN id SET DEFAULT nextval('public.user_skills_id_seq'::regclass);


--
-- Name: user_statuses id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_statuses ALTER COLUMN id SET DEFAULT nextval('public.user_statuses_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	production	2024-12-05 22:56:09.222101	2024-12-05 22:56:09.222106
\.


--
-- Data for Name: classe_persos; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.classe_persos (id, name, description, created_at, updated_at) FROM stdin;
13	Sénateur	Politicien influent.	2024-12-07 09:05:42.287608	2024-12-07 09:05:42.287608
14	Bio-savant	Expert en sciences de la vie.	2024-12-07 09:05:42.290972	2024-12-07 09:05:42.290972
15	Autodidacte	Un apprenant autonome.	2024-12-07 09:05:42.293604	2024-12-07 09:05:42.293604
16	Mercenaire	Un combattant à louer.	2024-12-07 09:05:42.296088	2024-12-07 09:05:42.296088
17	Cyber-ingénieur	Spécialiste des technologies avancées.	2024-12-07 09:05:42.29933	2024-12-07 09:05:42.29933
18	Contrebandier	Expert dans l'art de la contrebande.	2024-12-07 09:05:42.302401	2024-12-07 09:05:42.302401
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.groups (id, name, description, created_at, updated_at) FROM stdin;
9	MJ	Le groupe des Maîtres du Jeu. Prosternez vous.	2024-12-07 09:05:42.240812	2024-12-07 09:05:42.240812
10	PNJ	Le groupe des marchands et auxiliaires de jeu	2024-12-07 09:05:42.246478	2024-12-07 09:05:42.246478
11	PJ	Les joueurs jouent au jeu	2024-12-07 09:05:42.252406	2024-12-07 09:05:42.252406
12	Hackers	Les hackers peuvent hacker les données des autres	2024-12-07 09:05:42.256939	2024-12-07 09:05:42.256939
\.


--
-- Data for Name: holonews; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.holonews (id, title, content, user_id, created_at, updated_at, target_user, target_group) FROM stdin;
1	Bienvenue sur l’appli Star Wars !	Coucou bande de bras cassés !	15	2024-12-07 10:29:19.746432	2024-12-07 10:29:19.746432	\N	all
\.


--
-- Data for Name: inventory_objects; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.inventory_objects (id, name, category, description, price, rarity, created_at, updated_at) FROM stdin;
80	Medipack	soins	Redonne en PV le jet de médecine du soigneur divisé par deux.	50	Commun	2024-12-07 09:05:42.547289	2024-12-07 09:05:42.547289
81	Medipack +	soins	Redonne en PV le jet de médecine du soigneur divisé par deux +1D	200	Unco	2024-12-07 09:05:42.551619	2024-12-07 09:05:42.551619
82	Medipack Deluxe	soins	Redonne en PV le plein jet de médecine du soigneur	500	Rare	2024-12-07 09:05:42.554796	2024-12-07 09:05:42.554796
83	Antidote	soins	Soigne le statut empoisonné, +1D PV	200	Unco	2024-12-07 09:05:42.557639	2024-12-07 09:05:42.557639
84	Extrait de Nysillin	soins	Plante soignante de Félucia: +2D PV immédiat en action de soutien	150	Unco	2024-12-07 09:05:42.56101	2024-12-07 09:05:42.56101
85	Baume de Kolto	soins	Baume miraculeux disparu de Manaan. +4D PV immédiat action soutien	800	Très rare	2024-12-07 09:05:42.564707	2024-12-07 09:05:42.564707
86	Sérum de Thyffera	soins	Guérit les maladies communes	300	Commun	2024-12-07 09:05:42.568039	2024-12-07 09:05:42.568039
87	Rétroviral kallidahin	soins	Guérit les maladies virales communes	500	Commun	2024-12-07 09:05:42.574755	2024-12-07 09:05:42.574755
88	Draineur de radiations	soins	Guérit la radioactivité	1000	Unco	2024-12-07 09:05:42.577606	2024-12-07 09:05:42.577606
89	Trompe-la-mort	soins	Soigne +2D PV à qqun passé sous -10 PV il y a – de 2 tours	2000	Rare	2024-12-07 09:05:42.585416	2024-12-07 09:05:42.585416
90	Homéopathie	soins	Soigne intégralement un personnage qui est à 5 PV ou moins de son maximum	0	Don	2024-12-07 09:05:42.592717	2024-12-07 09:05:42.592717
91	Poisipatch	patch	Quand le porteur est empoisonné, le patch libère un antidote	50	\N	2024-12-07 09:05:42.597041	2024-12-07 09:05:42.597041
92	Traumapatch	patch	Quand le porteur est blessé, le patch libère 1D PV de bacta	50	\N	2024-12-07 09:05:42.600846	2024-12-07 09:05:42.600846
93	Stimpatch	patch	Quand le porteur est sonné, le stimpatch le stimule	50	\N	2024-12-07 09:05:42.604521	2024-12-07 09:05:42.604521
94	Fibripatch	patch	Quand le porteur tombe agonisant, le patch le stabilise	80	\N	2024-12-07 09:05:42.608293	2024-12-07 09:05:42.608293
95	Vigpatch	patch	Le porteur a +1DD à son prochain jet de dégâts Mains nues/AB	100	\N	2024-12-07 09:05:42.611858	2024-12-07 09:05:42.611858
96	Focuspatch	patch	Quand le porteur fait moins de la moitié du max d'un jet de précision, +1D préci	100	\N	2024-12-07 09:05:42.615353	2024-12-07 09:05:42.615353
97	Répercupatch	patch	Quand le porteur reçoit des dégâts, il gagne 1 action immédiate	200	\N	2024-12-07 09:05:42.618884	2024-12-07 09:05:42.618884
98	Vitapatch	patch	Quand le porteur tombe agonisant, le patch le remet à 0 PV	300	\N	2024-12-07 09:05:42.622241	2024-12-07 09:05:42.622241
99	Composant	ingredient	Une pièce basique pour fabriquer ou réparer des objets techniques divers. Se trouve partout	10	Commun	2024-12-07 09:05:42.625131	2024-12-07 09:05:42.625131
100	Transmetteur	ingredient	Le transmetteur est une pièce commune qui permet la transmission d'informations par ondes	50	Commun	2024-12-07 09:05:42.628058	2024-12-07 09:05:42.628058
101	Répartiteur	ingredient	Le répartiteur est une pièce commune qui assure la redistribution de l'énergie	50	Commun	2024-12-07 09:05:42.630862	2024-12-07 09:05:42.630862
102	Répercuteur	ingredient	Le répercuteur est une pièce commune qui permet d'amorcer des systèmes complexes	100	Commun	2024-12-07 09:05:42.634082	2024-12-07 09:05:42.634082
103	Circuit de retransmission	ingredient	Fabriqué par le fabricant à base de 2 compos et 1 transmetteur, le circuit permet d'améliorer la connectique	200	Commun	2024-12-07 09:05:42.637665	2024-12-07 09:05:42.637665
104	Répartiteur fuselé	ingredient	Fabriqué par le fabricant à base de 2 compos et 1 répartiteur, le rép. fuselé redistribue mieux l'énergie	200	Commun	2024-12-07 09:05:42.640209	2024-12-07 09:05:42.640209
105	Convecteur thermique	ingredient	Le convecteur thermique est une pièce peu commune qui a pour fonction la concentration d'énergie	300	Unco	2024-12-07 09:05:42.642476	2024-12-07 09:05:42.642476
106	Senseur	ingredient	Le senseur est une pièce peu commune qui a de multiples paramètres de détection par balayage d'ondes	200	Unco	2024-12-07 09:05:42.644917	2024-12-07 09:05:42.644917
107	Fuseur	ingredient	Le fuseur est une pièce peu commune qui sert à fusionner des particules instables d'énergie	400	Unco	2024-12-07 09:05:42.647204	2024-12-07 09:05:42.647204
108	Propulseur	ingredient	Le propulseur est une pièce peu commune dédiée aux systèmes de propulsion	400	Unco	2024-12-07 09:05:42.649597	2024-12-07 09:05:42.649597
109	Vibro-érecteur	ingredient	Fabriqué avec 2 compos + 1 répercuteur + 1 circ de retr + 1 rép fuselé, sert à activer des puissants systèmes	500	Unco	2024-12-07 09:05:42.652021	2024-12-07 09:05:42.652021
110	Commandes	ingredient	Les commandes sont une pièce rare qui consiste en une interface de contrôle de systèmes complexes	1000	Rare	2024-12-07 09:05:42.654218	2024-12-07 09:05:42.654218
111	Injecteur de photon	ingredient	L'injecteur de photon est une pièce rare qui sert à la transmission d'énergie dans la technologie de pointe	2000	Rare	2024-12-07 09:05:42.656572	2024-12-07 09:05:42.656572
112	Chrysalis	ingredient	La chrysalis est une pièce très rare, qui catalyse l'énergie du vide pour l'alimentation en énergie	5000	Très rare	2024-12-07 09:05:42.658923	2024-12-07 09:05:42.658923
113	Vibreur	ingredient	Le vibreur est une pièce commune qui concentre l'énergie par émission d'ondes vibratoires	200	Commun	2024-12-07 09:05:42.661603	2024-12-07 09:05:42.661603
114	Micro-générateur	ingredient	Le micro-générateur est une pièce commune qui assure l'apport en énergie dans la micro-ingénierie	300	Commun	2024-12-07 09:05:42.667099	2024-12-07 09:05:42.667099
115	Synthé-gilet	ingredient	Nécessaire pour crafter différents types d'améliorations d'armures	200	Commun	2024-12-07 09:05:42.669439	2024-12-07 09:05:42.669439
116	Interface cyber	ingredient	L'interface cyber est une pièce peu commune qui sert à créer une interface homme / machine	500	Unco	2024-12-07 09:05:42.672094	2024-12-07 09:05:42.672094
117	Pile à protons	ingredient	La pile à protons une pièce rare qui sert à capter les particules de protons environnantes	800	Rare	2024-12-07 09:05:42.674483	2024-12-07 09:05:42.674483
118	Lingot de Phrik	ingredient	Le lingot de phrik est un échantillon peu commun d'un métal résistant	500	Unco	2024-12-07 09:05:42.679923	2024-12-07 09:05:42.679923
119	Filet de Lommite	ingredient	Le filet de lommite est un échantillon rare d'un métal très résistant	1000	Rare	2024-12-07 09:05:42.685471	2024-12-07 09:05:42.685471
120	Lingot de Duracier	ingredient	Le lingot de duracier est un alliage très rare et extrêmement résistant	3000	Très rare	2024-12-07 09:05:42.689368	2024-12-07 09:05:42.689368
121	Fiole	ingredient	Un contenant pour diverses préparations de potions et poisons	30	Commun	2024-12-07 09:05:42.691923	2024-12-07 09:05:42.691923
122	Matière organique	ingredient	Un substras de matière organique amalgamée	80	Commun	2024-12-07 09:05:42.694692	2024-12-07 09:05:42.694692
123	Dose de bacta	ingredient	Une dose de bacta, cette substance régénératrice utilisée dans les medipacks et cuves à bacta	100	Unco	2024-12-07 09:05:42.69719	2024-12-07 09:05:42.69719
124	Dose de kolto	ingredient	Une dose de kolto, une substance régénératrice rare et très efficace	300	Rare	2024-12-07 09:05:42.700126	2024-12-07 09:05:42.700126
125	Jeu d'éprouvettes	ingredient	Un simple jeu d'éprouvettes pour l'artisanat du biosavant	50	Commun	2024-12-07 09:05:42.702771	2024-12-07 09:05:42.702771
126	Pique chirurgicale	ingredient	Une pique chirurgicale à usage unique pour les manipulations techniques difficiles du biosavant	300	Unco	2024-12-07 09:05:42.706788	2024-12-07 09:05:42.706788
127	Diffuseur aérosol	ingredient	Un diffuseur aérosol à ouverture manuelle ou retardée, pour y mettre des choses méchantes à diffuser dedans	100	Unco	2024-12-07 09:05:42.712491	2024-12-07 09:05:42.712491
128	Matière explosive	ingredient	La matière explosive est une matière malléable et adaptable, qui sert à la fabrication d'explosifs	200	Commun	2024-12-07 09:05:42.715794	2024-12-07 09:05:42.715794
129	Poudre de Zabron	ingredient	La poudre de zabron est issu d'un sable très volatile qui se disperse en de grandes volutes de fumée rose	100	Commun	2024-12-07 09:05:42.718637	2024-12-07 09:05:42.718637
130	Cardamine	ingredient	Une petite plante commune aux propriétés diurétiques, et toxique à haute dose	30	Commun	2024-12-07 09:05:42.721352	2024-12-07 09:05:42.721352
131	Kava	ingredient	Une plante hallucinogène, aux effets réactifs divers en mélange avec d’autres plantes	50	Commun	2024-12-07 09:05:42.723887	2024-12-07 09:05:42.723887
132	Passiflore	ingredient	Une famille de plantes peu commune, à très haute toxicité	100	Unco	2024-12-07 09:05:42.726482	2024-12-07 09:05:42.726482
133	Neurotoxique	ingredient	Une substance neurotoxique particulièrement dangereuse	300	Rare	2024-12-07 09:05:42.729102	2024-12-07 09:05:42.729102
134	Processeur basique (10)	ingredient	Un processeur de base dont la vitesse permettra à la plupart des navordinateurs et droïdes de fonctionner	200	Commun	2024-12-07 09:05:42.731619	2024-12-07 09:05:42.731619
135	Processeur 12	ingredient	Un processeur un peu amélioré, de façon à intégrer quelques fonctions plus poussées	400	Commun	2024-12-07 09:05:42.735109	2024-12-07 09:05:42.735109
136	Processeur 14	ingredient	Un processeur plus puissant dont la vitesse permettra à des systèmes plus complexes de fonctionner	600	Unco	2024-12-07 09:05:42.738508	2024-12-07 09:05:42.738508
137	Processeur 16	ingredient	Un processeur très puissant qui conviendra pour faire tourner la plupart des systèmes	1500	Rare	2024-12-07 09:05:42.741106	2024-12-07 09:05:42.741106
138	Processeur 18	ingredient	Un processeur rare d'une technologie de pointe dont la puissance énorme permet de gérer presque tout système	3000	Rare	2024-12-07 09:05:42.744776	2024-12-07 09:05:42.744776
139	Processeur 20	ingredient	Un processeur rare et de très haute technologie dont la puissance extrême permet de gérer tout type de système	6000	Très rare	2024-12-07 09:05:42.749915	2024-12-07 09:05:42.749915
\.


--
-- Data for Name: pet_inventory_objects; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.pet_inventory_objects (id, pet_id, inventory_object_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pets; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.pets (id, name, race, hp_current, hp_max, res_corp, res_corp_bonus, speed, damage_1, damage_2, accuracy, dodge, weapon_1, weapon_2, created_at, updated_at) FROM stdin;
1	Jiya	Jawa	20	20	2	1	5	5	5	6	5	Sabre Laser	Fusil Blaster +2	2024-12-07 09:05:44.267084	2024-12-07 09:05:44.267084
2	R4-X3	Astromex	12	12	1	2	2	6	\N	3	1	Lance-Flammes	\N	2024-12-07 09:05:44.273338	2024-12-07 09:05:44.273338
3	Elenoa	Cathar	18	18	1	2	8	4	5	7	8	Griffes	Fusil Blaster Wilson	2024-12-07 09:05:44.279634	2024-12-07 09:05:44.279634
4	Étoile	Twilek	\N	25	2	\N	4			\N	4			2024-12-07 10:24:43.059112	2024-12-07 10:24:43.059112
5	N°13	Rancor modifié (agi drigg fort + regen gaia fort)	\N	30	4	\N	6	Griffe 5dd	Charge 6dd	6	5			2024-12-07 10:55:18.086193	2024-12-07 10:55:18.086193
\.


--
-- Data for Name: races; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.races (id, name, description, created_at, updated_at) FROM stdin;
11	Humain	Une espèce polyvalente.	2024-12-07 09:05:42.270431	2024-12-07 09:05:42.270431
12	Kaminien	Les bio-savants de Kamino.	2024-12-07 09:05:42.274394	2024-12-07 09:05:42.274394
13	Codru'Ji	Les êtres à quatre bras de Munto Codru.	2024-12-07 09:05:42.277555	2024-12-07 09:05:42.277555
14	Torydarien	Les ingénieurs venus de Toydaria.	2024-12-07 09:05:42.281524	2024-12-07 09:05:42.281524
15	Clawdite	Les métamorphes de Zolan.	2024-12-07 09:05:42.284301	2024-12-07 09:05:42.284301
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.schema_migrations (version) FROM stdin;
20240910105136
20240910110052
20240910110140
20240910110505
20240910201915
20240910201922
20241002171237
20241003174316
20241010133310
20241031105554
20241031105751
20241031105839
20241031111522
20241104120241
20241111134651
20241112112516
20241112140659
20241112141124
20241114151934
20241114152725
20241114153350
20241114153357
20241203183123
20241204161004
20241204204529
20241205173030
20241206113801
20241206113819
20241206113826
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.skills (id, name, description, created_at, updated_at) FROM stdin;
5	Médecine	Compétence pour soigner les autres.	2024-12-07 09:05:44.237853	2024-12-07 09:05:44.237853
6	Résistance Corporelle	Réduit les dégâts subis en fonction du jet de résistance corporelle.	2024-12-07 09:05:44.241671	2024-12-07 09:05:44.241671
7	Ingénierie	Compétence pour crafter des trucs	2024-12-07 09:05:44.24804	2024-12-07 09:05:44.24804
\.


--
-- Data for Name: statuses; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.statuses (id, name, description, color, created_at, updated_at) FROM stdin;
27	En forme	En pleine santé	#00FF00	2024-12-07 09:05:42.752772	2024-12-07 09:05:42.752772
28	Empoisonné	Empoisonné	#7F00FF	2024-12-07 09:05:42.755554	2024-12-07 09:05:42.755554
29	Irradié	Irradié par des radiations	#FFD700	2024-12-07 09:05:42.757977	2024-12-07 09:05:42.757977
30	Agonisant	À l'agonie, proche de la mort	#8B0000	2024-12-07 09:05:42.760579	2024-12-07 09:05:42.760579
31	Mort	Le joueur est mort	#A9A9A9	2024-12-07 09:05:42.763067	2024-12-07 09:05:42.763067
32	Inconscient	Inconscient, dans le coma	#808080	2024-12-07 09:05:42.76544	2024-12-07 09:05:42.76544
33	Malade	Affection commune	#FF4500	2024-12-07 09:05:42.76785	2024-12-07 09:05:42.76785
34	Maladie Virale	Affection commune	#FF4600	2024-12-07 09:05:42.770097	2024-12-07 09:05:42.770097
35	Gravement Malade	Affection grave	#FF4700	2024-12-07 09:05:42.772378	2024-12-07 09:05:42.772378
36	Paralysé	Impossible de bouger	#FF69B4	2024-12-07 09:05:42.77453	2024-12-07 09:05:42.77453
37	Sonné	Désorienté	#4682B4	2024-12-07 09:05:42.776919	2024-12-07 09:05:42.776919
38	Aveugle	Impossible de voir	#000000	2024-12-07 09:05:42.779214	2024-12-07 09:05:42.779214
39	Sourd	Impossible d'entendre	#C0C0C0	2024-12-07 09:05:42.781515	2024-12-07 09:05:42.781515
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.transactions (id, sender_id, receiver_id, amount, created_at, updated_at) FROM stdin;
31	16	17	1	2024-12-07 10:30:57.221404	2024-12-07 10:30:57.221404
32	16	17	649	2024-12-07 10:31:38.512087	2024-12-07 10:31:38.512087
33	15	16	200	2024-12-07 15:53:46.074879	2024-12-07 15:53:46.074879
34	15	18	400	2024-12-07 15:54:51.414203	2024-12-07 15:54:51.414203
35	15	21	500	2024-12-07 15:57:56.949087	2024-12-07 15:57:56.949087
36	15	21	20000	2024-12-08 00:08:18.470524	2024-12-08 00:08:18.470524
37	15	16	3000	2024-12-08 10:09:08.33568	2024-12-08 10:09:08.33568
38	15	18	3000	2024-12-08 10:09:18.711055	2024-12-08 10:09:18.711055
39	15	17	3000	2024-12-08 10:09:26.757237	2024-12-08 10:09:26.757237
40	15	19	3000	2024-12-08 10:09:38.520237	2024-12-08 10:09:38.520237
41	15	20	3000	2024-12-08 10:09:46.349236	2024-12-08 10:09:46.349236
42	18	15	60	2024-12-08 10:37:51.634869	2024-12-08 10:37:51.634869
43	16	15	200	2024-12-08 11:06:06.371127	2024-12-08 11:06:06.371127
44	16	15	50	2024-12-08 11:07:14.82208	2024-12-08 11:07:14.82208
45	15	21	9000	2024-12-08 11:29:33.521672	2024-12-08 11:29:33.521672
46	15	21	800	2024-12-08 11:30:52.586597	2024-12-08 11:30:52.586597
47	15	21	70	2024-12-08 11:31:37.444506	2024-12-08 11:31:37.444506
48	15	21	4500	2024-12-08 11:33:49.632401	2024-12-08 11:33:49.632401
49	15	21	200	2024-12-08 11:34:45.658685	2024-12-08 11:34:45.658685
50	21	16	150	2024-12-08 11:38:17.790464	2024-12-08 11:38:17.790464
51	21	15	10000	2024-12-08 11:38:51.332529	2024-12-08 11:38:51.332529
52	21	15	9000	2024-12-08 11:43:55.583958	2024-12-08 11:43:55.583958
\.


--
-- Data for Name: user_inventory_objects; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.user_inventory_objects (id, user_id, inventory_object_id, quantity, created_at, updated_at) FROM stdin;
13	19	81	2	2024-12-07 10:39:40.960497	2024-12-07 10:39:40.960497
16	17	85	1	2024-12-07 10:41:14.164644	2024-12-07 10:41:14.164644
17	17	89	3	2024-12-07 10:41:21.521872	2024-12-07 10:41:21.521872
18	17	86	5	2024-12-07 10:42:06.387894	2024-12-07 10:42:06.387894
19	17	87	2	2024-12-07 10:42:36.876244	2024-12-07 10:42:36.876244
20	17	83	4	2024-12-07 10:42:44.319318	2024-12-07 10:42:44.319318
22	19	85	1	2024-12-07 10:44:14.894351	2024-12-07 10:44:14.894351
23	17	90	1	2024-12-07 12:33:15.046629	2024-12-07 12:33:15.046629
15	17	81	2	2024-12-07 10:40:02.965549	2024-12-07 15:32:44.571714
24	17	122	15	2024-12-07 15:50:44.11273	2024-12-07 15:50:44.11273
12	18	80	1	2024-12-07 10:39:26.960466	2024-12-07 17:59:59.313618
14	17	80	8	2024-12-07 10:39:55.766991	2024-12-07 21:24:31.448382
25	19	98	1	2024-12-07 21:29:45.264105	2024-12-07 21:29:45.264105
26	18	93	1	2024-12-07 21:30:09.17589	2024-12-07 21:30:09.17589
27	21	98	1	2024-12-07 21:34:51.59752	2024-12-07 21:34:51.59752
28	18	81	5	2024-12-08 10:45:37.061637	2024-12-08 10:51:36.646825
21	17	88	6	2024-12-07 10:43:57.942458	2024-12-08 10:52:19.440744
29	16	81	3	2024-12-08 10:54:53.0485	2024-12-08 10:54:55.192812
\.


--
-- Data for Name: user_skills; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.user_skills (id, user_id, skill_id, mastery, bonus, created_at, updated_at) FROM stdin;
14	16	6	1	4	2024-12-07 10:28:29.95628	2024-12-07 10:29:08.86894
15	18	5	3	0	2024-12-07 10:29:14.172038	2024-12-07 10:29:14.172038
16	18	6	3	2	2024-12-07 10:29:14.179618	2024-12-07 10:29:14.179618
13	16	5	3	0	2024-12-07 10:28:29.943387	2024-12-07 10:29:21.794578
18	19	6	3	4	2024-12-07 10:29:22.857756	2024-12-07 10:29:22.857756
19	17	5	6	1	2024-12-07 12:33:13.017733	2024-12-07 12:33:13.017733
20	17	6	2	1	2024-12-07 12:33:13.024551	2024-12-07 12:33:13.024551
21	21	5	1	2	2024-12-07 12:57:45.299144	2024-12-07 13:17:58.69761
22	21	6	2	1	2024-12-07 12:57:45.316926	2024-12-07 13:17:58.729308
17	19	5	2	0	2024-12-07 10:29:22.845595	2024-12-08 10:50:38.429283
\.


--
-- Data for Name: user_statuses; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.user_statuses (id, user_id, status_id, created_at, updated_at) FROM stdin;
603	16	27	2024-12-08 10:36:19.063428	2024-12-08 10:36:19.063428
610	17	27	2024-12-08 10:54:31.956165	2024-12-08 10:54:31.956165
369	20	27	2024-12-07 21:23:41.917446	2024-12-07 21:23:41.917446
370	21	27	2024-12-07 21:24:12.107978	2024-12-07 21:24:12.107978
371	18	27	2024-12-07 21:24:31.455913	2024-12-07 21:24:31.455913
643	19	27	2024-12-18 12:01:44.289172	2024-12-18 12:01:44.289172
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: ubicja6nk7obgf
--

COPY public.users (id, email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at, created_at, updated_at, credits, username, group_id, hp_max, hp_current, shield_state, shield_max, shield_current, race_id, classe_perso_id, xp, total_xp, robustesse, homeopathie, patch, echani_shield_state, echani_shield_current, echani_shield_max, luck, pet_id) FROM stdin;
19	pluto@rpg.com	$2a$12$WzgqBpnt27BvutBR5KRjIeWb9aOydbDqc2Wg56lA/Op4J0vbGi9YG	\N	\N	2024-12-08 10:58:21.751694	2024-12-07 09:05:43.739846	2024-12-18 12:01:44.279246	2500	pluto	11	35	19	f	50	50	11	16	0	14	t	f	98	f	0	0	f	\N
16	jarluc@rpg.com	$2a$12$XNDlu4M0dKcRWvWeKEFDceszFqgzWgGWyaqUkHinKPIWCc0u8Vgn2	\N	\N	\N	2024-12-07 09:05:43.012242	2024-12-08 11:38:17.788977	33500	jarluc	11	33	33	\N	0	0	11	13	16	16	t	f	\N	\N	0	0	f	\N
21	mas@rpg.com	$2a$12$KNVBW3/zFQifgV8c9.3zxuAQ.muOC4U28cGYqGvMhocaGMeXcuX4G	\N	\N	2024-12-08 10:50:34.201471	2024-12-07 09:05:44.227028	2024-12-08 11:43:55.580609	23740	mas tandor	11	21	21	f	20	20	15	18	16	16	f	f	98	t	30	30	t	\N
15	mj@rpg.com	$2a$12$hyDXXi.MN8emkdUYflaSu.Hf2jvOGPqwhBNXor/U5yeiJTtct583e	\N	\N	\N	2024-12-07 09:05:42.541279	2024-12-08 11:43:55.582711	68640	mj	9	1000	1000	\N	\N	\N	\N	\N	0	0	f	f	\N	\N	\N	\N	f	\N
17	kay@rpg.com	$2a$12$OdsGb4Ab2NtSlAaxgJuCle0C4SiJ/bYEZybbTHNB2ztKUkx97ksmu	\N	\N	2024-12-07 10:08:04.001873	2024-12-07 09:05:43.257437	2024-12-08 10:55:12.65015	3670	kaey noah	11	27	27	f	50	50	12	14	0	14	f	t	\N	f	50	50	f	5
18	nuok@rpg.com	$2a$12$Rd/FM9AesaB1VOQNEKuP0uAkqgZI5.Uk22YpV..12XtSf8ZqsVgRu	\N	\N	2024-12-07 21:22:19.563448	2024-12-07 09:05:43.49837	2024-12-08 10:57:13.706207	3450	nuok	11	38	38	\N	0	0	13	15	1	13	f	f	93	\N	0	0	f	\N
20	viggo@rpg.com	$2a$12$cuSTQRyB2j2S.niF5E/7XOf8I9YT9cl3Lk8kuIzcU88qkYu6TQzrm	\N	\N	2024-12-07 15:31:50.127977	2024-12-07 09:05:43.979707	2024-12-08 10:09:46.347212	17350	viggo	11	22	22	t	50	10	14	17	28	28	f	f	\N	f	0	0	f	\N
\.


--
-- Name: classe_persos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.classe_persos_id_seq', 33, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.groups_id_seq', 33, true);


--
-- Name: holonews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.holonews_id_seq', 33, true);


--
-- Name: inventory_objects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.inventory_objects_id_seq', 165, true);


--
-- Name: pet_inventory_objects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.pet_inventory_objects_id_seq', 1, false);


--
-- Name: pets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.pets_id_seq', 33, true);


--
-- Name: races_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.races_id_seq', 33, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.skills_id_seq', 33, true);


--
-- Name: statuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.statuses_id_seq', 66, true);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.transactions_id_seq', 66, true);


--
-- Name: user_inventory_objects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.user_inventory_objects_id_seq', 33, true);


--
-- Name: user_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.user_skills_id_seq', 33, true);


--
-- Name: user_statuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.user_statuses_id_seq', 643, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ubicja6nk7obgf
--

SELECT pg_catalog.setval('public.users_id_seq', 33, true);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: classe_persos classe_persos_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.classe_persos
    ADD CONSTRAINT classe_persos_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: holonews holonews_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.holonews
    ADD CONSTRAINT holonews_pkey PRIMARY KEY (id);


--
-- Name: inventory_objects inventory_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.inventory_objects
    ADD CONSTRAINT inventory_objects_pkey PRIMARY KEY (id);


--
-- Name: pet_inventory_objects pet_inventory_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.pet_inventory_objects
    ADD CONSTRAINT pet_inventory_objects_pkey PRIMARY KEY (id);


--
-- Name: pets pets_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_pkey PRIMARY KEY (id);


--
-- Name: races races_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.races
    ADD CONSTRAINT races_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: user_inventory_objects user_inventory_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_inventory_objects
    ADD CONSTRAINT user_inventory_objects_pkey PRIMARY KEY (id);


--
-- Name: user_skills user_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT user_skills_pkey PRIMARY KEY (id);


--
-- Name: user_statuses user_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_statuses
    ADD CONSTRAINT user_statuses_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_holonews_on_user_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_holonews_on_user_id ON public.holonews USING btree (user_id);


--
-- Name: index_pet_inventory_objects_on_inventory_object_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_pet_inventory_objects_on_inventory_object_id ON public.pet_inventory_objects USING btree (inventory_object_id);


--
-- Name: index_pet_inventory_objects_on_pet_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_pet_inventory_objects_on_pet_id ON public.pet_inventory_objects USING btree (pet_id);


--
-- Name: index_user_inventory_objects_on_inventory_object_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_user_inventory_objects_on_inventory_object_id ON public.user_inventory_objects USING btree (inventory_object_id);


--
-- Name: index_user_inventory_objects_on_user_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_user_inventory_objects_on_user_id ON public.user_inventory_objects USING btree (user_id);


--
-- Name: index_user_skills_on_skill_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_user_skills_on_skill_id ON public.user_skills USING btree (skill_id);


--
-- Name: index_user_skills_on_user_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_user_skills_on_user_id ON public.user_skills USING btree (user_id);


--
-- Name: index_user_statuses_on_status_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_user_statuses_on_status_id ON public.user_statuses USING btree (status_id);


--
-- Name: index_user_statuses_on_user_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_user_statuses_on_user_id ON public.user_statuses USING btree (user_id);


--
-- Name: index_users_on_classe_perso_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_users_on_classe_perso_id ON public.users USING btree (classe_perso_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_group_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_users_on_group_id ON public.users USING btree (group_id);


--
-- Name: index_users_on_pet_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_users_on_pet_id ON public.users USING btree (pet_id);


--
-- Name: index_users_on_race_id; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE INDEX index_users_on_race_id ON public.users USING btree (race_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: ubicja6nk7obgf
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: pet_inventory_objects fk_rails_0a4e8b4f34; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.pet_inventory_objects
    ADD CONSTRAINT fk_rails_0a4e8b4f34 FOREIGN KEY (inventory_object_id) REFERENCES public.inventory_objects(id);


--
-- Name: user_inventory_objects fk_rails_0d32cbbac4; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_inventory_objects
    ADD CONSTRAINT fk_rails_0d32cbbac4 FOREIGN KEY (inventory_object_id) REFERENCES public.inventory_objects(id);


--
-- Name: user_statuses fk_rails_2178592333; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_statuses
    ADD CONSTRAINT fk_rails_2178592333 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_statuses fk_rails_351517c602; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_statuses
    ADD CONSTRAINT fk_rails_351517c602 FOREIGN KEY (status_id) REFERENCES public.statuses(id);


--
-- Name: user_skills fk_rails_59acb6e327; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT fk_rails_59acb6e327 FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: users fk_rails_949b733b46; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_949b733b46 FOREIGN KEY (race_id) REFERENCES public.races(id);


--
-- Name: pet_inventory_objects fk_rails_d251778216; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.pet_inventory_objects
    ADD CONSTRAINT fk_rails_d251778216 FOREIGN KEY (pet_id) REFERENCES public.pets(id);


--
-- Name: users fk_rails_d446e4364b; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_d446e4364b FOREIGN KEY (classe_perso_id) REFERENCES public.classe_persos(id);


--
-- Name: user_inventory_objects fk_rails_e38f675ec5; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_inventory_objects
    ADD CONSTRAINT fk_rails_e38f675ec5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_f3954f5069; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_f3954f5069 FOREIGN KEY (pet_id) REFERENCES public.pets(id);


--
-- Name: users fk_rails_f40b3f4da6; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_f40b3f4da6 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: holonews fk_rails_fa06bcecc4; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.holonews
    ADD CONSTRAINT fk_rails_fa06bcecc4 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_skills fk_rails_fe61b6a893; Type: FK CONSTRAINT; Schema: public; Owner: ubicja6nk7obgf
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT fk_rails_fe61b6a893 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: ubicja6nk7obgf
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- Name: FUNCTION pg_stat_statements_reset(userid oid, dbid oid, queryid bigint); Type: ACL; Schema: public; Owner: rdsadmin
--

GRANT ALL ON FUNCTION public.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint) TO ubicja6nk7obgf;


--
-- Name: extension_before_drop; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER extension_before_drop ON ddl_command_start
   EXECUTE FUNCTION _heroku.extension_before_drop();


ALTER EVENT TRIGGER extension_before_drop OWNER TO heroku_admin;

--
-- Name: log_create_ext; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER log_create_ext ON ddl_command_end
   EXECUTE FUNCTION _heroku.create_ext();


ALTER EVENT TRIGGER log_create_ext OWNER TO heroku_admin;

--
-- Name: log_drop_ext; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER log_drop_ext ON sql_drop
   EXECUTE FUNCTION _heroku.drop_ext();


ALTER EVENT TRIGGER log_drop_ext OWNER TO heroku_admin;

--
-- Name: validate_extension; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER validate_extension ON ddl_command_end
   EXECUTE FUNCTION _heroku.validate_extension();


ALTER EVENT TRIGGER validate_extension OWNER TO heroku_admin;

--
-- PostgreSQL database dump complete
--

