import json

def lambda_handler(event, context):
    request = event.get("request", {})
    user_attributes = request.get("userAttributes", {})

    tenant_id = user_attributes.get("custom:tenant_id", "")
    tenant_slug = user_attributes.get("custom:tenant_slug", "")
    app_role = user_attributes.get("custom:app_role", "")
    email = user_attributes.get("email", "")

    group_config = request.get("groupConfiguration", {})
    groups = group_config.get("groupsToOverride", []) or event.get("request", {}).get("groupConfiguration", {}).get("groupsToOverride", [])

    claims = {
        "tenant_id": tenant_id,
        "tenant_slug": tenant_slug,
        "app_role": app_role,
        "email": email
    }

    if groups:
        claims["groups"] = ",".join(groups)

    event["response"] = {
        "claimsOverrideDetails": {
            "claimsToAddOrOverride": claims
        }
    }

    return event