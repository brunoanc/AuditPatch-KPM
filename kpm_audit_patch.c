#include <compiler.h>
#include <kpmodule.h>
#include <hook.h>
#include <linux/printk.h>
#include <linux/string.h>
#include <linux/kernel.h>

KPM_NAME("AuditPatch KPM");
KPM_VERSION("v0.0.2");
KPM_LICENSE("GPL v3");
KPM_AUTHOR("Bruno Ancona");
KPM_DESCRIPTION("Replace sensitive context in audit log");

struct audit_buffer;

void (*audit_log_format)(struct audit_buffer *ab, const char *fmt, ...);

void before_audit_log_format(hook_fargs3_t *args, void *udata)
{
    const char *fmt = (const char *)args->arg1;
    const char *percent = strchr(fmt, '%');

    if (percent && percent[1] == 's' && strchr(percent + 1, '%') == NULL && strstr(fmt, "tcontext=")) {
        const char *tcontext = (const char *)args->arg2;

        if (unlikely(strstr(tcontext, ":su:") || strstr(tcontext, ":magisk:"))) {
            static const char *kernel_str = "u:r:priv_app:s0:c512,c768";
            args->arg2 = (uintptr_t)kernel_str;
        }
    }
}

static long audit_patch_init(const char *args, const char *event, void *__user reserved)
{
    pr_info("kpm_audit_patch: module init\n");

    audit_log_format = (typeof(audit_log_format))kallsyms_lookup_name("audit_log_format");

    if (!audit_log_format) {
        pr_err("kpm_audit_patch: Failed to find function audit_log_format\n");
        return -1;
    }

    hook_err_t err = hook_wrap3(audit_log_format, before_audit_log_format, 0, 0);

    if (err) {
        pr_err("kpm_audit_patch: Failed to hook audit_log_format: %d\n", err);
        return err;
    }

    pr_info("kpm_audit_patch: audit_log_format hooked\n");
    return 0;
}

static long audit_patch_exit(void *__user reserved)
{
    if (audit_log_format) unhook(audit_log_format);
    pr_info("kpm_audit_patch: module exit\n");
    return 0;
}

KPM_INIT(audit_patch_init);
KPM_EXIT(audit_patch_exit);
