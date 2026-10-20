package cn.surveyking.server.domain.dto;

import lombok.Data;

import java.util.List;

/**
 * 角色题库授权的请求体。repoIds 为完整的目标集合，不仅包含本次新增或删除的项。
 */
@Data
public class RoleRepoRequest {

	private String roleId;

	private List<String> repoIds;

}
