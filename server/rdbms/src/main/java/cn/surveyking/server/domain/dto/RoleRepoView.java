package cn.surveyking.server.domain.dto;

import lombok.Data;

import java.util.Date;
import java.util.List;

/**
 * 角色题库授权页面需要的全部数据：题库清单 + 哪些已授权给该角色。
 */
@Data
public class RoleRepoView {

	private List<Item> items;

	@Data
	public static class Item {

		private String id;

		private String name;

		private String mode;

		private Boolean isPractice;

		private Boolean shared;

		private String category;

		private String description;

		private Date createAt;

		/** 该题库是否已授权给当前角色 */
		private Boolean granted;

	}

}
