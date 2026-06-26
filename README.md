# aws-cicd-ec2

Node.js REST API deployed to EC2 using AWS CodePipeline, CodeBuild, and CodeDeploy. CI/CD demo project.

## What I Learned

### Project Structure

```
aws-cicd-ec2/
├── app.js              # Express REST API (entry point)
├── package.json        # Node dependencies & scripts
├── buildspec.yml       # CodeBuild instructions
├── appspec.yml         # CodeDeploy instructions
└── scripts/
    ├── stop_app.sh     # Kills running Node process
    ├── install_deps.sh # Runs npm install on EC2
    ├── start_app.sh    # Starts app in background with nohup
    └── validate.sh     # Hits /health endpoint to confirm deploy
```

### Running Locally

```bash
npm install
node app.js
# App runs on http://localhost:3000/health
```

### Key Concepts

#### buildspec.yml (CodeBuild)
- Controls what happens during the **build phase** in CodeBuild
- Phases: install → pre_build → build → post_build
- `artifacts` section defines what files get packaged and sent to CodeDeploy
- `runtime-versions` expects major version only (e.g., `nodejs: 20`, not `20.19.0`)
- `artifacts` and `cache` are **top-level keys**, not nested inside `phases`

#### appspec.yml (CodeDeploy)
- Controls what happens during **deployment to EC2**
- `files` section maps source bundle → destination on instance
- `hooks` section maps lifecycle events → shell scripts
- Each hook script must be **executable** (Linux `chmod +x`)
- Typos in YAML keys (like `file_extists_behavior`) silently break things

#### CodeDeploy Lifecycle Events (in order)

| # | Event | What happens | Hook |
|---|-------|-------------|------|
| 1 | ApplicationStop | Stops previous version | scripts/stop_app.sh |
| 2 | DownloadBundle | Pulls artifact from S3 | (automatic) |
| 3 | BeforeInstall | Pre-install cleanup | scripts/stop_app.sh |
| 4 | Install | Copies files to destination | (automatic) |
| 5 | AfterInstall | Install deps, set permissions | scripts/install_deps.sh |
| 6 | ApplicationStart | Start the new app | scripts/start_app.sh |
| 7 | ValidateService | Health check to confirm it works | scripts/validate.sh |

### Common Mistakes & Fixes

| Mistake | Fix |
|---------|-----|
| Service role field needs ARN not name | Use full ARN: `arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME` |
| "CodeDeploy cannot assume the role" | Update role trust policy to allow `codedeploy.amazonaws.com` |
| Scripts not executable on Linux | Windows creates files with wrong line endings (`\r\n`). Use LF |
| `start_app.sh` doesn't actually start app | Must use `nohup node app.js &` so it runs in background |
| Mixed up script contents | Double-check each script does what its filename says |
| Deployment fails with generic error | Check specific lifecycle event in console, then view logs on instance |
| `file_extists_behavior` typo | Correct spelling: `file_exists_behavior` |

### IAM Roles

- **EC2 Instance Profile role**: allows the instance to pull from S3 and talk to CodeDeploy agent
  - Trust: `ec2.amazonaws.com`
- **CodeDeploy Service role**: allows CodeDeploy to manage deployments
  - Trust: `codedeploy.amazonaws.com`
  - Policy: `AWSCodeDeployRole`
- These should be **separate roles** (don't combine them)

### Debugging Deployments

```bash
# SSH into EC2 and check agent logs
cat /var/log/aws/codedeploy-agent/codedeploy-agent.log

# Check if agent is running
sudo service codedeploy-agent status

# Check deployment script output
cat /opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log
```

### EC2 Instance Tags

- CodeDeploy uses **tags** to find target instances
- Deployment Group config: "Deploy to instances where Tag Key = Value"
- Example: `Environment = Production`
- Instance must have that exact tag for CodeDeploy to target it

### Key Exam Takeaways

- `buildspec.yml` = CodeBuild (compile/package)
- `appspec.yml` = CodeDeploy (deploy to instances)
- The generic "too many instances failed" error means check the specific lifecycle event
- Lifecycle event order matters. If AfterInstall fails, ApplicationStart never runs
- Scripts run as the user specified in `runas` (typically `root`)

