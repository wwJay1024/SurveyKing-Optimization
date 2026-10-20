SET MODE MySQL;
SET NON_KEYWORDS KEY, VALUE;


-- ----------------------------
-- Table structure for t_account
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_account (
  id varchar(64) NOT NULL COMMENT 'ID',
  user_type varchar(100) NOT NULL DEFAULT 'SysUser' COMMENT '用户类型',
  user_id varchar(64) NOT NULL COMMENT '用户ID',
  auth_type varchar(20) NOT NULL DEFAULT 'PWD' COMMENT '认证方式',
  auth_account varchar(100) NOT NULL COMMENT '用户名',
  auth_secret varchar(64) DEFAULT NULL COMMENT '密码',
  secret_salt varchar(32) DEFAULT NULL COMMENT '加密盐',
  status int NOT NULL DEFAULT '1' COMMENT '用户状态',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  oauth_identity_key varchar(220) GENERATED ALWAYS AS ((case when ((is_deleted = 0) and (auth_type in ('GOOGLE','WECHAT'))) then concat(auth_type,':',auth_account) else NULL end)),
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_account_oauth_identity ON t_account(oauth_identity_key);
CREATE INDEX IF NOT EXISTS idx_account_user_auth ON t_account(user_id,auth_type,is_deleted);

-- ----------------------------
-- Records of t_account
-- ----------------------------
BEGIN;
INSERT INTO t_account (id, user_type, user_id, auth_type, auth_account, auth_secret, secret_salt, status, is_deleted, create_at, create_by, update_at, update_by) VALUES ('1', 'SysUser', '1457995481966747649', 'PWD', 'admin', '$2a$10$vZk9P3XtbD2KrdLbQYPvBuPAkkUda0OlkDg7io1Q6VEtfFPig/tqO', NULL, 1, 0, '2021-11-09 16:56:26', NULL, '2022-02-01 23:57:27', '1457995481966747649');
COMMIT;

-- ----------------------------
-- Table structure for t_answer
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_answer (
  id varchar(64) NOT NULL,
  project_id varchar(64) NOT NULL,
  temp_answer text COMMENT '暂存答案',
  survey longtext COMMENT '问卷',
  answer text COMMENT '问卷答案',
  attachment varchar(1024) DEFAULT NULL COMMENT '问卷元数据',
  meta_info text COMMENT '问卷元数据',
  temp_save int DEFAULT NULL COMMENT '0暂存 1已完成',
  exam_info text COMMENT '考试信息',
  exam_exercise_type varchar(4) DEFAULT NULL COMMENT '考试练习类型',
  exam_score float DEFAULT NULL COMMENT '考试分数',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  repo_id varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS key_answer_pid ON t_answer(project_id);

-- ----------------------------
-- Records of t_answer
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_comm_dict
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_comm_dict (
  id varchar(64) NOT NULL,
  code varchar(256) DEFAULT NULL COMMENT '字典编码',
  name varchar(256) DEFAULT NULL COMMENT '字典中文名称',
  remark varchar(256) DEFAULT NULL COMMENT '备注信息',
  dict_type int DEFAULT '1' COMMENT '字典类型 1:问卷字典 2:系统字典',
  create_at datetime DEFAULT NULL COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at datetime DEFAULT NULL COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_comm_dict
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_comm_dict_item
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_comm_dict_item (
  id varchar(64) NOT NULL,
  dict_code varchar(256) DEFAULT NULL COMMENT '字典编码',
  item_name varchar(256) DEFAULT NULL COMMENT '字典项中文名称',
  item_value varchar(256) NOT NULL COMMENT '字典项值',
  item_order int DEFAULT NULL COMMENT '字典顺序',
  item_level int DEFAULT NULL COMMENT '层级',
  parent_item_value varchar(64) DEFAULT NULL COMMENT '父字典项值',
  create_at datetime DEFAULT NULL COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at datetime DEFAULT NULL COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id,item_value)
);

-- ----------------------------
-- Records of t_comm_dict_item
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_dashboard
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_dashboard (
  id varchar(64) NOT NULL COMMENT 'ID',
  key varchar(256) NOT NULL COMMENT '仪表盘组件key',
  type int DEFAULT NULL COMMENT '仪表盘分类',
  project_id varchar(64) DEFAULT NULL COMMENT '项目ID',
  setting varchar(1024) DEFAULT NULL COMMENT '仪表盘设置',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_dashboard
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_dept
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_dept (
  id varchar(64) NOT NULL COMMENT 'ID',
  parent_id varchar(64) NOT NULL,
  name varchar(64) DEFAULT NULL COMMENT '名称',
  short_name varchar(64) NOT NULL COMMENT '简称',
  code varchar(64) DEFAULT NULL COMMENT '数据权限类型',
  manager_id varchar(64) DEFAULT NULL COMMENT '扩展字段',
  sort_code int DEFAULT NULL,
  property_json varchar(256) DEFAULT NULL COMMENT '扩展字段',
  status varchar(20) DEFAULT NULL COMMENT '扩展字段',
  remark varchar(256) DEFAULT NULL COMMENT '扩展字段',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_dept
-- ----------------------------
BEGIN;
INSERT INTO t_dept (id, parent_id, name, short_name, code, manager_id, sort_code, property_json, status, remark, is_deleted, create_at, create_by, update_at, update_by) VALUES ('1', '0', '卷王问卷', 'surveyking', 'surveyking', '1457995481966747649', NULL, NULL, NULL, NULL, 0, '2021-11-21 14:12:08', NULL, '2021-11-21 14:22:58', '1457995481966747649');
COMMIT;

-- ----------------------------
-- Table structure for t_file
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_file (
  id varchar(64) NOT NULL,
  original_name varchar(256) DEFAULT NULL,
  file_name varchar(256) DEFAULT NULL,
  file_path varchar(512) DEFAULT NULL,
  thumb_file_path varchar(512) DEFAULT NULL,
  storage_type int DEFAULT NULL,
  shared int DEFAULT '0',
  project_id varchar(64) DEFAULT NULL COMMENT '所属项目',
  question_id varchar(64) DEFAULT NULL COMMENT '所属问题',
  answer_id varchar(64) DEFAULT NULL COMMENT '绑定答卷',
  file_size bigint DEFAULT NULL COMMENT '文件大小（字节）',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_file_project_id ON t_file(project_id);
CREATE INDEX IF NOT EXISTS idx_file_answer_id ON t_file(answer_id);

-- ----------------------------
-- Records of t_file
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_position
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_position (
  id varchar(64) NOT NULL COMMENT 'ID',
  name varchar(50) NOT NULL,
  code varchar(20) DEFAULT NULL,
  is_virtual tinyint(1) NOT NULL COMMENT '是否虚拟岗',
  data_permission_type varchar(256) DEFAULT NULL COMMENT '数据权限类型',
  property_json varchar(20) DEFAULT NULL COMMENT '扩展字段',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_position
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_project
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_project (
  id varchar(64) NOT NULL,
  parent_id varchar(64) DEFAULT '0' COMMENT '父ID',
  name text COMMENT '项目名称',
  survey longtext COMMENT '问卷',
  setting text COMMENT '问卷设置',
  status int DEFAULT '0' COMMENT '0未发布 1已发布',
  mode varchar(32) DEFAULT NULL COMMENT '问卷模式',
  priority int DEFAULT '1000' COMMENT '优先级',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_project
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_project_partner
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_project_partner (
  id varchar(64) NOT NULL,
  uid varchar(64) DEFAULT NULL COMMENT '项目内唯一ID',
  project_id varchar(64) DEFAULT NULL COMMENT '项目id',
  type int DEFAULT NULL COMMENT '参与者类型',
  status int DEFAULT '0' COMMENT '0未访问 1已访问 2已答题',
  user_id varchar(64) DEFAULT NULL COMMENT '参与者id',
  user_name varchar(256) DEFAULT NULL COMMENT '参与者姓名',
  group_id varchar(64) DEFAULT NULL COMMENT '参与组id',
  data_permission text COMMENT '数据权限',
  initial_value text COMMENT '初始值',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_project_partner
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_repo
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_repo (
  id varchar(64) NOT NULL,
  name varchar(64) DEFAULT NULL COMMENT '标题',
  description varchar(512) DEFAULT NULL COMMENT '备注',
  category varchar(64) DEFAULT NULL COMMENT '题库分类',
  mode varchar(32) DEFAULT NULL COMMENT 'survey问卷 exam考试',
  shared tinyint(1) DEFAULT '0' COMMENT '1共享 0私有',
  tag varchar(512) DEFAULT NULL COMMENT '标签',
  priority int DEFAULT NULL COMMENT '排序优先级',
  setting text COMMENT '设置',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  is_practice tinyint DEFAULT NULL COMMENT '添加到练习题库 1是 0否',
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_repo
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_repo_partner
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_repo_partner (
  id varchar(64) NOT NULL,
  repo_id varchar(64) DEFAULT NULL COMMENT '题库id',
  user_id varchar(64) DEFAULT NULL COMMENT '成员id',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_repo_partner
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_role_repo
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_role_repo (
  id varchar(64) NOT NULL,
  role_id varchar(64) NOT NULL COMMENT '角色id',
  repo_id varchar(64) NOT NULL COMMENT '题库id',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_t_role_repo_role ON t_role_repo(role_id);
CREATE INDEX IF NOT EXISTS idx_t_role_repo_repo ON t_role_repo(repo_id);

-- ----------------------------
-- Records of t_role_repo
-- ----------------------------

-- ----------------------------
-- Table structure for t_repo_template
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_repo_template (
  id varchar(64) NOT NULL,
  template_id varchar(64) DEFAULT NULL COMMENT '模板id',
  repo_id varchar(64) DEFAULT NULL COMMENT '模板库id',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_repo_template
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_role
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_role (
  id varchar(64) NOT NULL COMMENT 'ID',
  name varchar(50) NOT NULL COMMENT '名称',
  code varchar(50) NOT NULL COMMENT '编码',
  remark varchar(100) DEFAULT NULL COMMENT '备注',
  authority varchar(3000) DEFAULT NULL COMMENT '权限列表',
  status tinyint(1) DEFAULT '1' COMMENT '1激活 0失活',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_role
-- ----------------------------
BEGIN;
INSERT INTO t_role (id, name, code, remark, authority, status, is_deleted, create_at, create_by, update_at, update_by) VALUES ('1457995481928998914', '超级管理员', 'admin', '系统初始化角色', 'answer,answer:list,answer:detail,answer:create,answer:update,answer:delete,answer:export,file,file:detail,file:list,file:import,file:delete,project,project:list,project:detail,project:create,project:update,project:delete,project:report,system,system:role,system:role:list,system:user,system:user:list,system:role:create,system:role:update,system:role:delete,system:user:create,system:user:update,system:user:updatePosition,system:user:delete,position,position:list,position:create,system:position,system:position:update,system:position:delete,system:org,system:org:list,system:org:create,system:org:update,system:org:delete,template,template:list,template:create,template:update,template:delete,system:position:list,system:position:create,system:dept,system:dept:list,system:dept:create,system:dept:update,system:dept:delete,repo,repo:list,repo:detail,repo:create,repo:update,repo:delete,user,user:update,answer:upload,system:dict,system:dict:update,system:dict:delete,system:dictItem,system:dictItem:list,system:dictItem:create,system:dictItem:import,system:dictItem:delete,system:dict:list,system:dict:create,exercise,exercise:list,repo:book,system:dictItem:update,home', 1, 0, '2021-11-09 16:56:26', NULL, '2025-08-08 10:04:12', '1457995481966747649');
COMMIT;

-- ----------------------------
-- Table structure for t_sys_info
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_sys_info (
  id varchar(64) NOT NULL COMMENT '主键',
  name varchar(64) DEFAULT NULL COMMENT '系统名称',
  description varchar(128) DEFAULT NULL COMMENT '系统描述信息',
  avatar varchar(64) DEFAULT NULL COMMENT '图标',
  locale varchar(64) DEFAULT NULL COMMENT '默认语言',
  version varchar(64) DEFAULT NULL COMMENT '版本号',
  setting varchar(1024) DEFAULT NULL COMMENT '其他系统设置',
  ai_setting text COMMENT 'AI设置',
  oauth_setting text COMMENT '第三方登录设置',
  register_info varchar(1024) DEFAULT NULL COMMENT '注册信息',
  is_default tinyint(1) DEFAULT NULL COMMENT '是否默认设置',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_sys_info
-- ----------------------------
BEGIN;
INSERT INTO t_sys_info (id, name, description, avatar, locale, version, setting, ai_setting, oauth_setting, register_info, is_default, create_at, create_by, update_at, update_by) VALUES ('1', '卷王问卷考试系统', '做更好的调查问卷系统', NULL, 'zh-CN', '{}', NULL, NULL, NULL, NULL, 1, '2022-02-11 10:13:19', NULL, '2022-11-07 15:13:02', NULL);
COMMIT;

-- ----------------------------
-- Table structure for t_tag
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_tag (
  id varchar(64) NOT NULL,
  entity_id varchar(64) DEFAULT NULL COMMENT '实体ID',
  name varchar(128) DEFAULT NULL COMMENT '名称',
  category varchar(256) DEFAULT NULL COMMENT '分类',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_tag
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_template
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_template (
  id varchar(64) NOT NULL,
  repo_id varchar(64) DEFAULT NULL,
  serial_no varchar(256) DEFAULT NULL COMMENT '序号',
  name varchar(1024) DEFAULT NULL COMMENT '模板标题',
  question_type varchar(64) DEFAULT NULL COMMENT '问题类型',
  template longtext COMMENT '模板',
  mode varchar(32) DEFAULT NULL COMMENT '模板模式 survey/exam',
  category varchar(256) DEFAULT NULL COMMENT '模板分类',
  tag varchar(512) DEFAULT NULL COMMENT '标签',
  priority int DEFAULT NULL COMMENT '排序优先级',
  preview_url varchar(512) DEFAULT NULL COMMENT '预览地址',
  shared tinyint(1) DEFAULT '0',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_template
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_user
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_user (
  id varchar(64) NOT NULL COMMENT 'ID',
  name varchar(50) NOT NULL COMMENT '真实姓名',
  dept_id varchar(20) DEFAULT NULL,
  gender varchar(10) DEFAULT NULL COMMENT '性别',
  birthday date DEFAULT NULL COMMENT '出生日期',
  phone varchar(20) DEFAULT NULL COMMENT '手机号',
  email varchar(50) DEFAULT NULL COMMENT 'Email',
  avatar varchar(200) DEFAULT NULL COMMENT '头像地址',
  status tinyint(1) NOT NULL DEFAULT '1' COMMENT '用户状态',
  is_deleted tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  profile varchar(255) DEFAULT NULL COMMENT '个人简介',
  correct_times int DEFAULT NULL COMMENT '错题答对清除次数',
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_user
-- ----------------------------
BEGIN;
INSERT INTO t_user (id, name, dept_id, gender, birthday, phone, email, avatar, status, is_deleted, create_at, create_by, update_at, update_by, profile, correct_times) VALUES ('1457995481966747649', 'Admin', '1', 'F', NULL, '13800138000', 'surveyking@qq.com', NULL, 1, 0, '2021-11-09 16:56:26', NULL, '2022-02-11 13:29:17', '1457995481966747649', 'hello surveyking~', NULL);
COMMIT;

-- ----------------------------
-- Table structure for t_user_book
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_user_book (
  id varchar(64) NOT NULL,
  name varchar(2048) DEFAULT NULL COMMENT '问题名称',
  template_id varchar(64) DEFAULT NULL COMMENT '模板ID',
  wrong_times int DEFAULT NULL COMMENT '错误次数',
  correct_times int DEFAULT NULL COMMENT '正确次数',
  note text COMMENT '笔记',
  status int DEFAULT NULL COMMENT '1标记为简单',
  type int DEFAULT NULL COMMENT '1错题 2收藏',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  repo_id varchar(256) DEFAULT NULL,
  is_marked tinyint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_user_book
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_user_position
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_user_position (
  id varchar(64) NOT NULL COMMENT 'ID',
  user_id varchar(64) NOT NULL,
  dept_id varchar(64) DEFAULT NULL,
  position_id varchar(64) DEFAULT NULL COMMENT '数据权限类型',
  is_primary_position tinyint(1) DEFAULT NULL COMMENT '是否主岗',
  propertyJson varchar(256) DEFAULT NULL COMMENT '扩展字段',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ----------------------------
-- Records of t_user_position
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_user_role
-- ----------------------------
CREATE TABLE IF NOT EXISTS t_user_role (
  id varchar(64) NOT NULL COMMENT 'ID',
  user_type varchar(100) NOT NULL DEFAULT 'SysUser' COMMENT '用户类型',
  user_id varchar(64) NOT NULL COMMENT '用户ID',
  role_id varchar(64) NOT NULL COMMENT '角色ID',
  create_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  create_by varchar(256) DEFAULT NULL,
  update_at timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  update_by varchar(256) DEFAULT NULL,
  PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_t_user_role ON t_user_role(user_type,user_id);

-- ----------------------------
-- Records of t_user_role
-- ----------------------------
BEGIN;
INSERT INTO t_user_role (id, user_type, user_id, role_id, create_at, create_by, update_at, update_by) VALUES ('1488542015867121666', 'SysUser', '1457995481966747649', '1457995481928998914', '2022-02-01 23:57:27', '1457995481966747649', NULL, NULL);
COMMIT;
