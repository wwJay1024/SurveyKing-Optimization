package cn.surveyking.server.api;

import cn.surveyking.server.domain.dto.RoleRepoRequest;
import cn.surveyking.server.domain.dto.RoleRepoView;
import cn.surveyking.server.service.RoleRepoService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 角色题库授权：接口和配套的管理页面。
 *
 * 页面单独放在 static/role-repo.html，通过 /role-repo 直接返回，
 * 不走前端 SPA 的路由，避免改动已经编译好的前端产物。
 */
@RestController
@RequiredArgsConstructor
public class RoleRepoApi {

	private final RoleRepoService roleRepoService;

	@Value("classpath:/static/role-repo.html")
	private Resource roleRepoPage;

	@GetMapping("${api.prefix}/system/role/repo")
	@PreAuthorize("hasAuthority('system:role:update')")
	public RoleRepoView describe(@RequestParam("roleId") String roleId) {
		return roleRepoService.describe(roleId);
	}

	@GetMapping("${api.prefix}/system/role/repo/counts")
	@PreAuthorize("hasAuthority('system:role:list')")
	public Map<String, Long> counts() {
		return roleRepoService.countByRole();
	}

	@PostMapping("${api.prefix}/system/role/repo/save")
	@PreAuthorize("hasAuthority('system:role:update')")
	public void save(@RequestBody RoleRepoRequest request) {
		roleRepoService.save(request);
	}

	@PostMapping("${api.prefix}/system/role/repo/sync")
	@PreAuthorize("hasAuthority('system:role:update')")
	public void syncMembers(@RequestParam("roleId") String roleId) {
		roleRepoService.syncMembers(roleId);
	}

	@GetMapping(value = "/role-repo", produces = MediaType.TEXT_HTML_VALUE)
	public ResponseEntity<Resource> page() {
		// 页面迭代频繁，每次都回源校验，避免浏览器长期用旧版本
		return ResponseEntity.ok()
				.contentType(MediaType.valueOf("text/html;charset=UTF-8"))
				.cacheControl(CacheControl.noCache())
				.body(roleRepoPage);
	}

}
