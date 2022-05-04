# Manual test that sending emails works

import emails
import json
import sys

if len(sys.argv) < 2:
    print(("Usage: "
           "python send_email.py <email_credentials_json> <recipient_email>"))
    sys.exit(1)


# Prepare the email
message = emails.html(
    html=("<h1>My message</h1><strong>I can reach you to tell you important "
          "data.gov news!</strong>"),
    subject="ATTN: Hello data.gov world",
    mail_from="test@ses-cbc2c1def2423951.ssb-dev.data.gov",
)

# Gather email settings
credentials = open(sys.argv[1], "r")
settings = json.load(credentials)
credentials.close()

# Send the email
r = message.send(
    to=sys.argv[2],
    smtp={
        "host": settings["credentials"]["smtp_server"],
        "port": 587,
        "timeout": 5,
        "user": settings["credentials"]["smtp_user"],
        "password": settings["credentials"]["smtp_password"],
        "tls": True,
    },
)

print(r)
assert r.status_code == 250
