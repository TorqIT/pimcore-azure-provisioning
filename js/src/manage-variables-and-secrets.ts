import { Octokit } from '@octokit/core'

async function test() {
    const octokit = new Octokit({
        auth: 'YOUR-TOKEN'
    })

    await octokit.request('PUT /repos/{owner}/{repo}/actions/secrets/{secret_name}', {
        owner: 'OWNER',
        repo: 'REPO',
        secret_name: 'SECRET_NAME',
        encrypted_value: 'c2VjcmV0',
        key_id: '012345678912345678',
        headers: {
            'X-GitHub-Api-Version': '2022-11-28'
        }
    })
}

test()