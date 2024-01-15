import { Octokit } from '@octokit/core'

async function test(auth: string, owner: string, repository: string, environmentName: string) {
    const octokit = new Octokit({
        auth: auth
    })

    await octokit.request(`PUT /repos/${owner}/${repository}/environments/${environmentName}`, {
        owner: owner,
        repo: repository,
        environment_name: environmentName,
        deployment_branch_policy: {
            protected_branches: false,
            custom_branch_policies: true
        },
        headers: {
            'X-GitHub-Api-Version': '2022-11-28'
        }
    })
}

test(process.argv[0], process.argv[1], process.argv[2], process.argv[3])