# Kanidm

## Argocd

```bash
# Create the client
kanidm system oauth2 create argocd "ArgoCD" https://insidan.linkopingsfallskarmsklubb.se/argocd

# Add redirect URI
kanidm system oauth2 add-redirect-url argocd https://insidan.linkopingsfallskarmsklubb.se/argocd/api/dex/callback

# Grant scopes
kanidm system oauth2 update-scope-map argocd argocd_users openid profile email groups

# Get client secret, add to secret manager
kanidm system oauth2 show-basic-secret argocd

# Dex doesn't support pkce
kanidm system oauth2 warning-insecure-client-disable-pkce argocd
```

## Skywinone

```bash
# Create the client
kanidm system oauth2 create skywinone "Skywin One" https://insidan.linkopingsfallskarmsklubb.se/skywinone

# Add redirect url
kanidm system oauth2 add-redirect-url skywinone https://insidan.linkopingsfallskarmsklubb.se/skywinone/oidc/callback^C

# Grant scopes
kanidm system oauth2 update-scope-map skywinone idm_all_persons openid profile groups

# Get client secret, add to secret manager
kanidm system oauth2 show-basic-secret argocd
 
```
