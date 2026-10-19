--
-- XXL-JOB (KingbaseES 兼容版本)
-- 信创改造：适配金仓数据库 KingbaseES
--

-- 创建数据库（Kingbase 语法）
CREATE DATABASE xxl_job
    WITH ENCODING 'UTF8'
         LC_COLLATE = 'zh_CN.UTF-8'
         LC_CTYPE = 'zh_CN.UTF-8'
         TABLESPACE = pg_default
         CONNECTION LIMIT = -1;

\c xxl_job

-- 切换至 utf8 编码
SET client_encoding TO 'UTF8';

-- ================== job group and registry ==================

CREATE TABLE xxl_job_group (
    id                    SERIAL,
    app_name              VARCHAR(64)         NOT NULL,
    name                  VARCHAR(64)         NOT NULL,
    address_type          SMALLINT            NOT NULL DEFAULT 0,
    address_list          TEXT,
    access_token          VARCHAR(255),
    update_time           TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX i_app_name ON xxl_job_group (app_name);

CREATE TABLE xxl_job_registry (
    id                    BIGSERIAL,
    registry_group        VARCHAR(50)         NOT NULL,
    registry_key          VARCHAR(255)        NOT NULL,
    registry_value        VARCHAR(255)        NOT NULL,
    update_time           TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX i_g_k_v ON xxl_job_registry (registry_group, registry_key, registry_value);

-- ================== job info ==================

CREATE TABLE xxl_job_info (
    id                        SERIAL,
    job_group                 INT                 NOT NULL,
    name                      VARCHAR(255)        NOT NULL,
    author                    VARCHAR(64),
    alarm_email               VARCHAR(255),
    schedule_type             VARCHAR(50)         NOT NULL DEFAULT 'NONE',
    schedule_conf             VARCHAR(128),
    misfire_strategy          VARCHAR(50)         NOT NULL DEFAULT 'DO_NOTHING',
    executor_route_strategy   VARCHAR(50),
    executor_handler          VARCHAR(255),
    executor_param            TEXT,
    executor_block_strategy   VARCHAR(50),
    executor_timeout          INT                 NOT NULL DEFAULT 0,
    executor_fail_retry_count INT                 NOT NULL DEFAULT 0,
    glue_type                 VARCHAR(50)         NOT NULL,
    glue_source               TEXT,
    glue_remark               VARCHAR(128),
    glue_updatetime           TIMESTAMP,
    child_jobid               VARCHAR(255),
    trigger_status            SMALLINT            NOT NULL DEFAULT 0,
    trigger_last_time         BIGINT              NOT NULL DEFAULT 0,
    trigger_next_time         BIGINT              NOT NULL DEFAULT 0,
    add_time                  TIMESTAMP,
    update_time               TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE INDEX i_trigger_time ON xxl_job_info (trigger_time);
CREATE INDEX i_handle_code ON xxl_job_info (trigger_status);
CREATE INDEX i_job_group ON xxl_job_info (job_group);
CREATE INDEX i_job_id ON xxl_job_info (job_group, job_id);

-- ================== job logglue ==================

CREATE TABLE xxl_job_logglue (
    id                        SERIAL,
    job_id                    INT                 NOT NULL,
    glue_type                 VARCHAR(50),
    glue_source               TEXT,
    glue_remark               VARCHAR(128)        NOT NULL,
    add_time                  TIMESTAMP,
    update_time               TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE INDEX i_glue_job_id ON xxl_job_logglue (job_id);

-- ================== job log and report ==================

CREATE TABLE xxl_job_log (
    id                        BIGSERIAL,
    job_group                 INT                 NOT NULL,
    job_id                    INT                 NOT NULL,
    executor_address          VARCHAR(255),
    executor_handler          VARCHAR(255),
    executor_param            TEXT,
    executor_sharding_param   VARCHAR(20),
    executor_fail_retry_count INT                 NOT NULL DEFAULT 0,
    trigger_time              TIMESTAMP,
    trigger_code              INT                 NOT NULL,
    trigger_msg               TEXT,
    handle_time               TIMESTAMP,
    handle_code               INT                 NOT NULL,
    handle_msg                TEXT,
    alarm_status              SMALLINT            NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
);

CREATE INDEX i_log_trigger_time ON xxl_job_log (trigger_time);
CREATE INDEX i_log_handle_code ON xxl_job_log (handle_code);
CREATE INDEX i_log_job_group ON xxl_job_log (job_group);
CREATE INDEX i_log_job_id ON xxl_job_log (job_id);
CREATE INDEX i_log_alarm_status ON xxl_job_log (alarm_status);

CREATE TABLE xxl_job_log_report (
    id                SERIAL,
    trigger_day       TIMESTAMP,
    running_count     INT                 NOT NULL DEFAULT 0,
    suc_count         INT                 NOT NULL DEFAULT 0,
    fail_count        INT                 NOT NULL DEFAULT 0,
    update_time       TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX i_trigger_day ON xxl_job_log_report (trigger_day);

-- ================== lock ==================

CREATE TABLE xxl_job_lock (
    lock_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (lock_name)
);

-- ================== user ==================

CREATE TABLE xxl_job_user (
    id                SERIAL,
    username          VARCHAR(50)         NOT NULL,
    password          VARCHAR(100)        NOT NULL,
    token             VARCHAR(100),
    role              SMALLINT            NOT NULL,
    permission        VARCHAR(255),
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX i_username ON xxl_job_user (username);

-- ================== for default data ==================

INSERT INTO xxl_job_group (id, app_name, name, address_type, access_token, update_time)
VALUES (1, 'xxl-job-executor-sample', '通用执行器Sample', 0, 'default_token', CURRENT_TIMESTAMP),
       (2, 'xxl-job-executor-sample-ai', 'AI执行器Sample', 0, 'default_token', CURRENT_TIMESTAMP);

-- 重置序列
SELECT setval('xxl_job_group_id_seq', 2);

INSERT INTO xxl_job_info (id, job_group, name, add_time, update_time, author, alarm_email,
                          schedule_type, schedule_conf, misfire_strategy, executor_route_strategy,
                          executor_handler, executor_param, executor_block_strategy, executor_timeout,
                          executor_fail_retry_count, glue_type, glue_source, glue_remark, glue_updatetime,
                          child_jobid, trigger_status, trigger_last_time, trigger_next_time)
VALUES (1, 1, '示例任务01', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'XXL', '', 'CRON', '0 0 0 * * ? *',
        'DO_NOTHING', 'FIRST', 'demoJobHandler', '', 'SERIAL_EXECUTION', 0, 0, 'BEAN', '', 'GLUE代码初始化',
        CURRENT_TIMESTAMP, '', 0, 0, 0),
       (2, 2, 'Ollama示例任务', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'XXL', '', 'NONE', '',
        'DO_NOTHING', 'FIRST', 'ollamaJobHandler', '{"input":"Java实现二叉树层序遍历","prompt":"你是一个研发工程师，擅长解决技术类问题。","model":"qwen3.5:0.8b"}', 'SERIAL_EXECUTION', 0, 0, 'BEAN', '', 'GLUE代码初始化',
        CURRENT_TIMESTAMP, '', 0, 0, 0),
       (3, 2, 'Dify示例任务', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'XXL', '', 'NONE', '',
        'DO_NOTHING', 'FIRST', 'difyWorkflowJobHandler', '{"inputs":{"input":"查询班级各学科前三名"},"user":"xxl-job","baseUrl":"http://localhost/v1","apiKey":"app-OUVgNUOQRIMokfmuJvBJoUTN"}', 'SERIAL_EXECUTION', 0, 0, 'BEAN', '', 'GLUE代码初始化',
        CURRENT_TIMESTAMP, '', 0, 0, 0),
       (4, 2, 'OpenClaw示例任务', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'XXL', '', 'NONE', '',
        'DO_NOTHING', 'FIRST', 'openClawJobHandler', '{"input":"查看下上海今天得天气，给出出游建议","prompt":"你是一个出游助手，擅长做旅游规划"}', 'SERIAL_EXECUTION', 0, 0, 'BEAN', '', 'GLUE代码初始化',
        CURRENT_TIMESTAMP, '', 0, 0, 0);

-- 重置序列
SELECT setval('xxl_job_info_id_seq', 4);

INSERT INTO xxl_job_user (id, username, password, role, permission)
VALUES (1, 'admin', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 1, NULL);

SELECT setval('xxl_job_user_id_seq', 1);

INSERT INTO xxl_job_lock (lock_name)
VALUES ('schedule_lock');
