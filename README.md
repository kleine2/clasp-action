# Clasp Action

This action uses [clasp](https://github.com/google/clasp) to push, deploy, create, delete or create and push projects on [Google Apps Script](https://developers.google.com/apps-script/). This action is running `clasp push -f` regardless of whether you select `push` or `deploy` as the command. This will force the remote manifest to be overwritten.

## Inputs

### `accessToken`

**Required** `access_token` written in `.clasprc.json`.

### `idToken`

**Required** `id_token` written in `.clasprc.json`.

### `refreshToken`

**Required** `refresh_token` written in `.clasprc.json`.

### `clientId`

**Required** `clientId` written in `.clasprc.json`.

### `clientSecret`

**Required** `clientSecret` written in `.clasprc.json`.

### `scriptId`

**Required** `scriptId` written in `.clasp.json`.

### `projectId`

`projectId` written in `.clasp.json`.

### `rootDir`

Directory where scripts are stored.

### `command`

**Required** Command to execute(`push`, `deploy`, `create`, `create_and_push` or `delete`).

If `deploy` is selected, this action is running `clasp push -f` just before.

Deploy works for max. 20 deployments due to Gas limit on active deployments and complexity to determine which deployment should be deleted.
Workaround : Set deployId.

### `description`

Description of the deployment.

### `deployId`

Deploy ID that will be updated with this push.

### `title`

Title of the script. Required when `command` is `create` or `create_and_push`.

### `email`

Email used for API authentication when using the `create_and_push` command.

### `password`

Password used for API authentication when using the `create_and_push` command.

## Outputs

### `script_url`

URL of the created script when `command` is `create` or `create_and_push`.

### `spreadsheet_url`

URL of the newly created spreadsheet document when `command` is `create` or `create_and_push`.

### `test_output`

Result from the test function executed during `create_and_push`.

## Example usage

### Case to push

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    scriptId: ${{ secrets.SCRIPT_ID }}
    projectId: ${{ secrets.PROJECT_ID }}
    command: 'push'
```

### Case to deploy

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    scriptId: ${{ secrets.SCRIPT_ID }}
    command: 'deploy'
```

### Case to deploy with description

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    scriptId: ${{ secrets.SCRIPT_ID }}
    command: 'deploy'
    description: 'Sample description'
```

### Case to specify the directory where scripts are stored

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}     
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    scriptId: ${{ secrets.SCRIPT_ID }}
    rootDir: 'src'
    command: 'push'
```

### Case to update a specific deploy

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    scriptId: ${{ secrets.SCRIPT_ID }}
    command: 'deploy'
    deployId: ${{ secrets.DEPLOY_ID }}
```

### Case to create a new script

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    command: 'create'
    title: 'My Spreadsheet Script'
    rootDir: 'src'
```

### Case to create a new script and push

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    command: 'create_and_push'
    title: 'My Spreadsheet Script'
    rootDir: 'src'
    email: ${{ secrets.EMAIL }}
    password: ${{ secrets.PASSWORD }}
```

### Case to delete a spreadsheet on pull request close

```yaml
- uses: daikikatsuragawa/clasp-action@v1.1.0
  with:
    accessToken: ${{ secrets.ACCESS_TOKEN }}
    idToken: ${{ secrets.ID_TOKEN }}
    refreshToken: ${{ secrets.REFRESH_TOKEN }}
    clientId: ${{ secrets.CLIENT_ID }}
    clientSecret: ${{ secrets.CLIENT_SECRET }}
    command: 'delete'
```

## License summary

This code is made available under the MIT license.
