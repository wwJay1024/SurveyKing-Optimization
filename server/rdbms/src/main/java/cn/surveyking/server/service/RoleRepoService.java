package cn.surveyking.server.service;

import cn.surveyking.server.domain.dto.RoleRepoRequest;
import cn.surveyking.server.domain.dto.RoleRepoView;

import java.util.Map;

/**
 * 角色维度的题库授权。权限落地方式是把角色下的用户展开写入 t_repo_partner，
 * 不修改题库可见性判断本身的实现。
 */
public interface RoleRepoService {

	/**
	 * 列出全部题库，并标出哪些已授权给该角色
	 */
	RoleRepoView describe(String roleId);

	/**
	 * 每个角色当前授权的题库数量，供角色列表直接展示
	 */
	Map<String, Long> countByRole();

	/**
	 * 以请求里的 repoIds 作为目标集合，覆盖该角色的题库授权
	 */
	void save(RoleRepoRequest request);

	/**
	 * 把角色当前成员重新展开写入 t_repo_partner，用于角色新增成员后补齐权限
	 */
	void syncMembers(String roleId);

}
