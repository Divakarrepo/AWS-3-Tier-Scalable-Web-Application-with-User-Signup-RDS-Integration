#!/bin/bash

# Update system
sudo yum update -y

# Install httpd
sudo yum install httpd -y

# Start nginx
systemctl start httpd
systemctl enable httpd

# Create HTML file
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Signup Page</title>
    <style>
        body {
            font-family: Arial;
            background: #f4f4f4;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        .box {
            background: white;
            padding: 30px;
            border-radius: 10px;
            width: 320px;
            box-shadow: 0px 0px 10px rgba(0,0,0,0.1);
        }

        input {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
        }

        button {
            width: 100%;
            padding: 10px;
            background: green;
            color: white;
            border: none;
        }
    </style>
</head>

<body>

<div class="box">
    <h2>Signup</h2>

    <input type="text" id="username" placeholder="Username">
    <input type="password" id="password" placeholder="Password">

    <button onclick="signup()">Sign Up</button>

    <p id="message"></p>
</div>

<script>
function signup() {
    const username = document.getElementById("username").value;
    const password = document.getElementById("password").value;

    fetch("http://web-elb-1828579201.us-east-1.elb.amazonaws.com/signup", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ username, password })
    })
    .then(res => res.json())
    .then(data => {
        document.getElementById("message").innerText = data.message || data.error;
    })
    .catch(() => {
        document.getElementById("message").innerText = "Error connecting backend";
    });
}
</script>

</body>
</html>
EOF