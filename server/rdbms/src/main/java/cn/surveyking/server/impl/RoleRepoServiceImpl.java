package cn.surveyking.server.impl;

import cn.surveyking.server.domain.dto.RoleRepoRequest;
import cn.surveyking.server.domain.dto.RoleRepoView;
import cn.surveyking.server.domain.model.Repo;
import cn.surveyking.server.domain.model.RepoPartner;
import cn.surveyking.server.domain.model.RoleRepo;
import cn.surveyking.server.domain.model.UserRole;
import cn.surveyking.server.mapper.RepoMapper;
import cn.surveyking.server.mapper.RepoPartnerMapper;
import cn.surveyking.server.mapper.RoleMapper;
import cn.surveyking.server.mapper.RoleRepoMapper;
import cn.surveyking.server.mapper.UserRoleMapper;
import cn.surveyking.server.service.BaseService;
import cn.surveyking.server.service.RoleRepoService;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.validation.ValidationException;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 角色题库授权的实现。
 *
 * 授权关系的权威记录在 t_role_repo；题库可见性仍然只认 t_repo_partner，
 * 所以授权时把角色下的用户展开写进去，撤销时再收回，避免改动现有的权限判断逻辑。
 */
@Service
@Transactional(rollbackFor = Exception.class)
@RequiredArgsConstructor
public class RoleRepoServiceImpl extends BaseService<RoleRepoMapper, RoleRepo> implements RoleRepoService {

	private final RoleMapper roleMapper;

	private final RepoMapper repoMapper;

	private final UserRoleMapper userRoleMapper;

	private final RepoPartnerMapper repoPartnerMapper;

	@Override
	public RoleRepoView describe(String roleId) {
		if (!StringUtils.hasText(roleId)) {
			throw new ValidationException("角色ID不能为空");
		}
		List<Repo> repos = repoMapper.selectList(Wrappers.<Repo>lambdaQuery().orderByDesc(Repo::getCreateAt));
		Set<String> granted = list(Wrappers.<RoleRepo>lambdaQuery().eq(RoleRepo::getRoleId, roleId)).stream()
				.map(RoleRepo::getRepoId).collect(Collectors.toSet());
		List<RoleRepoView.Item> items = repos.stream().map(repo -> {
			RoleRepoView.Item item = new RoleRepoView.Item();
			item.setId(repo.getId());
			item.setName(repo.getName());
			item.setMode(repo.getMode());
			item.setIsPractice(repo.getIsPractice());
			item.setShared(repo.getShared());
			item.setCategory(repo.getCategory());
			item.setDescription(repo.getDescription());
			item.setCreateAt(repo.getCreateAt());
			item.setGranted(granted.contains(repo.getId()));
			return item;
		}).collect(Collectors.toList());
		RoleRepoView view = new RoleRepoView();
		view.setItems(items);
		return view;
	}

	@Override
	public Map<String, Long> countByRole() {
		return list().stream()
				.collect(Collectors.groupingBy(RoleRepo::getRoleId, LinkedHashMap::new, Collectors.counting()));
	}

	@Override
	public void save(RoleRepoRequest request) {
		if (request == null || !StringUtils.hasText(request.getRoleId())) {
			throw new ValidationException("角色ID不能为空");
		}
		String roleId = request.getRoleId();
		if (roleMapper.selectById(roleId) == null) {
			throw new ValidationException("角色不存在");
		}
		Set<String> target = request.getRepoIds() == null ? Collections.emptySet()
				: request.getRepoIds().stream().filter(StringUtils::hasText)
						.collect(Collectors.toCollection(LinkedHashSet::new));
		Set<String> current = list(Wrappers.<RoleRepo>lambdaQuery().eq(RoleRepo::getRoleId, roleId)).stream()
				.map(RoleRepo::getRepoId).collect(Collectors.toSet());

		Set<String> toAdd = new LinkedHashSet<>(target);
		toAdd.removeAll(current);
		Set<String> toRemove = new LinkedHashSet<>(current);
		toRemove.removeAll(target);

		if (!toAdd.isEmpty()) {
			saveBatch(toAdd.stream().map(repoId -> {
				RoleRepo roleRepo = new RoleRepo();
				roleRepo.setRoleId(roleId);
				roleRepo.setRepoId(repoId);
				return roleRepo;
			}).collect(Collectors.toList()));
			materialize(roleId, toAdd);
		}
		if (!toRemove.isEmpty()) {
			remove(Wrappers.<RoleRepo>lambdaQuery().eq(RoleRepo::getRoleId, roleId)
					.in(RoleRepo::getRepoId, toRemove));
			dematerialize(roleId, toRemove);
		}
	}

	@Override
	public void syncMembers(String roleId) {
		if (!StringUtils.hasText(roleId)) {
			throw new ValidationException("角色ID不能为空");
		}
		Set<String> repoIds = list(Wrappers.<RoleRepo>lambdaQuery().eq(RoleRepo::getRoleId, roleId)).stream()
				.map(RoleRepo::getRepoId).collect(Collectors.toSet());
		if (repoIds.isEmpty()) {
			return;
		}
		materialize(roleId, repoIds);
	}

	/**
	 * 把角色下所有用户对这些题库的授权补齐
	 */
	private void materialize(String roleId, Collection<String> repoIds) {
		List<String> userIds = roleUserIds(roleId);
		if (userIds.isEmpty() || repoIds.isEmpty()) {
			return;
		}
		List<RepoPartner> exist = repoPartnerMapper.selectList(Wrappers.<RepoPartner>lambdaQuery()
				.in(RepoPartner::getRepoId, repoIds).in(RepoPartner::getUserId, userIds));
		Set<String> keys = exist.stream().map(p -> p.getRepoId() + "|" + p.getUserId()).collect(Collectors.toSet());
		for (String repoId : repoIds) {
			for (String userId : userIds) {
				if (keys.add(repoId + "|" + userId)) {
					RepoPartner partner = new RepoPartner();
					partner.setRepoId(repoId);
					partner.setUserId(userId);
					repoPartnerMapper.insert(partner);
				}
			}
		}
	}

	/**
	 * 收回这些题库的授权。用户如果还通过别的角色持有同一题库，则保留。
	 */
	private void dematerialize(String roleId, Collection<String> repoIds) {
		List<String> userIds = roleUserIds(roleId);
		if (userIds.isEmpty()) {
			return;
		}
		for (String userId : userIds) {
			List<String> otherRoleIds = userRoleMapper
					.selectList(Wrappers.<UserRole>lambdaQuery().eq(UserRole::getUserId, userId)
							.ne(UserRole::getRoleId, roleId))
					.stream().map(UserRole::getRoleId).distinct().collect(Collectors.toList());
			Set<String> stillGranted = otherRoleIds.isEmpty() ? Collections.emptySet()
					: list(Wrappers.<RoleRepo>lambdaQuery().in(RoleRepo::getRoleId, otherRoleIds)).stream()
							.map(RoleRepo::getRepoId).collect(Collectors.toSet());
			for (String repoId : repoIds) {
				if (stillGranted.contains(repoId)) {
					continue;
				}
				repoPartnerMapper.delete(Wrappers.<RepoPartner>lambdaQuery()
						.eq(RepoPartner::getUserId, userId).eq(RepoPartner::getRepoId, repoId));
			}
		}
	}

	private List<String> roleUserIds(String roleId) {
		return userRoleMapper
				.selectList(Wrappers.<UserRole>lambdaQuery().eq(UserRole::getRoleId, roleId)
						.eq(UserRole::getUserType, "SysUser"))
				.stream().map(UserRole::getUserId).distinct().collect(Collectors.toList());
	}

}
