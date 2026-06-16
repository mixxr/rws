
## Change Organization
**Pay attention**: this setting has to be done a organization level, not at project level

```
gcloud organizations add-iam-policy-binding organizations/1983...227 --member="user:<account>@gmail.com" --role="roles/orgpolicy.policyAdmin"
```
## Change Policy
```
gcloud org-policies set-policy <file>.yaml
```

- oldpolicy.yaml (deprecated)
```
name: projects/invcerts/policies/iam.disableServiceAccountKeyCreation
spec:
  rules:
  - enforce: false
```

- policy.yaml 
    - additionally, you can consider to setup the new policy contraint (defined by Google, it makes the above policy deprecated): 
```
name: projects/invcerts/policies/iam.managed.disableServiceAccountKeyCreation
spec:
  rules:
  - enforce: false
```  

## Service Key
Once the organization and policy are done, you can create a new service-account and the related JSON Service Key and use it into the GApps Script:
```
const service_account = {
  private_key: '-----BEGIN PRIVATE KEY-----\n...N4=\n-----END PRIVATE KEY-----\n',
  client_email: '<service-account>@<project>.iam.gserviceaccount.com'
};
```