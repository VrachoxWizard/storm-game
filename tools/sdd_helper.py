import sys
import os
import re
import subprocess

def get_git_root():
    res = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
    return res.stdout.strip()

def cmd_workspace(plan_file):
    root = get_git_root()
    slug = os.path.splitext(os.path.basename(plan_file))[0]
    base = os.path.join(root, ".superpowers", "sdd")
    w_dir = os.path.join(base, slug)
    os.makedirs(w_dir, exist_ok=True)
    with open(os.path.join(base, ".gitignore"), "w", encoding="utf-8") as f:
        f.write("*\n")
    print(w_dir)
    return w_dir

def cmd_task_brief(plan_file, task_num, out_file=None):
    if not out_file:
        w_dir = cmd_workspace(plan_file)
        out_file = os.path.join(w_dir, f"task-{task_num}-brief.md")
    
    with open(plan_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    in_fence = False
    in_task = False
    task_lines = []
    
    pattern = re.compile(rf"^#+\s+Task\s+{task_num}(?:[^0-9]|$)")
    next_task_pattern = re.compile(r"^#+\s+Task\s+[0-9]+(?:[^0-9]|$)")
    
    for line in lines:
        if line.strip().startswith("```"):
            in_fence = not in_fence
        if not in_fence:
            if pattern.match(line):
                in_task = True
            elif in_task and next_task_pattern.match(line):
                break
        if in_task:
            task_lines.append(line)
            
    if not task_lines:
        sys.stderr.write(f"Task {task_num} not found in {plan_file}\n")
        sys.exit(3)
        
    with open(out_file, "w", encoding="utf-8") as f:
        f.writelines(task_lines)
        
    print(f"wrote {out_file}: {len(task_lines)} lines")
    return out_file

def cmd_review_package(plan_file, base, head, out_file=None):
    if not out_file:
        w_dir = cmd_workspace(plan_file)
        base_short = subprocess.run(["git", "rev-parse", "--short", base], capture_output=True, text=True, check=True, encoding="utf-8", errors="replace").stdout.strip()
        head_short = subprocess.run(["git", "rev-parse", "--short", head], capture_output=True, text=True, check=True, encoding="utf-8", errors="replace").stdout.strip()
        out_file = os.path.join(w_dir, f"review-{base_short}..{head_short}.diff")
        
    log_out = subprocess.run(["git", "log", "--oneline", f"{base}..{head}"], capture_output=True, text=True, check=True, encoding="utf-8", errors="replace").stdout
    stat_out = subprocess.run(["git", "diff", "--stat", f"{base}..{head}"], capture_output=True, text=True, check=True, encoding="utf-8", errors="replace").stdout
    diff_out = subprocess.run(["git", "diff", "-U10", f"{base}..{head}"], capture_output=True, text=True, check=True, encoding="utf-8", errors="replace").stdout
    
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(f"# Review package: {base}..{head}\n\n")
        f.write("## Commits\n")
        f.write(log_out + "\n\n")
        f.write("## Files changed\n")
        f.write(stat_out + "\n\n")
        f.write("## Diff\n")
        f.write(diff_out + "\n")
        
    print(f"wrote {out_file}")
    return out_file

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python tools/sdd_helper.py [workspace|brief|review] <args>")
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "workspace":
        cmd_workspace(sys.argv[2])
    elif cmd == "brief":
        out = sys.argv[4] if len(sys.argv) > 4 else None
        cmd_task_brief(sys.argv[2], sys.argv[3], out)
    elif cmd == "review":
        out = sys.argv[5] if len(sys.argv) > 5 else None
        cmd_review_package(sys.argv[2], sys.argv[3], sys.argv[4], out)
