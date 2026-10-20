package cn.surveyking.server.domain.model;

import cn.surveyking.server.core.model.BaseModel;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 角色与题库的授权关系。一条记录表示某个角色被授予了某个题库。
 *
 * 实际的题库可见性不读这张表，而是在授权时把角色下的用户展开写入 t_repo_partner，
 * 复用原有的 hasPracticePermission 判断。这张表用于页面回显和撤销时的反查。
 */
@Data
@TableName(value = "t_role_repo", autoResultMap = true)
@EqualsAndHashCode(callSuper = false)
public class RoleRepo extends BaseModel {

	private String roleId;

	private String repoId;

}
