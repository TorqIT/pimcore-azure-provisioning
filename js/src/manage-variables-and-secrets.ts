import { Octokit } from '@octokit/core'

async function test(owner: string, repo: string, environmentName: string) {
    const octokit = new Octokit({
        auth: ''
    })

    await octokit.request(`PUT /repos/${owner}/${repo}/environments/${environmentName}`, {
        owner: 'OWNER',
        repo: 'REPO',
        environment_name: 'ENVIRONMENT_NAME',
        deployment_branch_policy: {
            protected_branches: false,
            custom_branch_policies: true
        },
        headers: {
            'X-GitHub-Api-Version': '2022-11-28'
        }
    })
}

test(process.argv[0], process.argv[1], process.argv[2])