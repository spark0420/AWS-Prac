# Week 3 — Decentralized Authentication

## Setup Cognito User Pool
1. Go to Cognito in AWS console
2. Create a user pool
    - Provider type = Cognito user pool
    - Cognito user pool sign-in options = Email
    - Password policy mode = Cognito defauls
    - Multi-factor authentication = No MFA
    - User account recovery = Enable self-service account recovery, Email Only
    - Additional attribute = name, preferred_username
    - I am not using Amazon SES service
    - I am not using Cognito Hosted UI
    - App type = Public client
    - I am not using client secret 

We are using AWS amplify to implement authentication in the front-end which uses JavaScript
> References: https://docs.amplify.aws/lib/auth/emailpassword/q/platform/js/

### Install AWS amplify library by running the below in /frontend-react-js
```sh
npm i aws-amplify --save
```
> the --save flag would update the dependencies in the project's package. json file, but npm install now includes this functionality by default. At this point if you want to prevent npm install from saving dependencies, you have to use the --no-save flag.

### Import the Amplify library in App.js 
```js
import { Amplify } from 'aws-amplify';
```

### Configure Amplify in App.js
```js
Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```

### Now we need to set Environment variables for the variables above
### Set them under front-end in Docker-compose.yml file
```yml
REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_USER_POOLS_ID: "us-west-2_tFqwGCzXW"
REACT_APP_CLIENT_ID: "33tcb80psa28sn9qk9bufock1s"
```
> These information can be found in AWS console > Cognito > User pool

Based on the log-in status, we will show certain contents in the main page or not.
To do so, we need to check the authentication in HomeFeedPage.js.

### Import the Amplify library in frontend-react-js/src/pages/HomeFeedPage.js
```js
import { Auth } from 'aws-amplify';
```

### Add a function to check authentication
```js
// set a state
const [user, setUser] = React.useState(null);

// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};
```
> Because some functions in DesktopNavigaion.js and DesktopSidebar uses the 'user' info that we are passing from the fuction 'checkAuth', they will show or not show some contents based on the authentication

### Update profileInfo.js to enable Cognito authenticatio there as well
### Import the Amplify library in profileInfo.js 
```js
import { Auth } from 'aws-amplify';
```

### Replace Sign-out fuction that were using cookies
```js
const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```

## Implement Custom Signin Page

Update SigninPage.js to enable Cognito authenticatio there as well
### Import the Amplify library in SigninPage.js 
```js
import { Auth } from 'aws-amplify';
```

### Replace onsubmit function that were using cookies
```js
const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();

    Auth.signIn(email, password)
      .then(user => {
        console.log('user', user)
        localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
        window.location.href = "/"
      })
      .catch(error => {
        if (error.code == 'UserNotConfirmedException') {
          window.location.href = "/confirm"
        }
        setErrors(error.message)
      });
    return false
  }
```
> Here, we uare using 'setErrors' instead of 'setCognitoErrors'
> Upon sign-in, the fuction above returns an access_token and saves it in a localStorage

## Result from Implementing Custom Signin Page

<img src = "images/SignIn_result.png" >

> Because I used an incorrect username and password, it shows an error message. 
> Network console should show an error saying "Uncaught (in promise) NotAuthorizedException: Incorrect username or password" at this stage. Mine is not showing it since I already set authorization in the server-side and set a different error message.

### Create a user For testing

Create a user using AWS Cognito console
When you create a user, its status set to FORCE_CHANGE_PASSWORD at the beginning.
AWS console does not allow it to happen using AWS console.
Therefore, use CLI 

In terminal, run the following with correct values
```sh
aws cognito-idp admin-set-user-password \
  --user-pool-id <your-user-pool-id> \
  --username <username> \
  --password <password> \
  --permanent
```

## Implement Custom Signup Page

### Import the Amplify library in SignupPage.js 
```js
import { Auth } from 'aws-amplify';
```

### Replace onsubmit function that were using cookies
```js
const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();

    Auth.signIn(email, password)
      .then(user => {
        console.log('user', user)
        localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
        window.location.href = "/"
      })
      .catch(error => {
        if (error.code == 'UserNotConfirmedException') {
          window.location.href = "/confirm"
        }
        setErrors(error.message)
      });
    return false
  }
```

## Implement Custom Confirmation Page

### Import the Amplify library in ConfirmationPage.js 
```js
import { Auth } from 'aws-amplify';
```

### Replace resend and onsubmit function that were using cookies
```js
const resend_code = async (event) => {
    setErrors('')
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      setCodeSent(true)
    } catch (err) {
      // does not return a code
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message == 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message == "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.")   
      }
    }
  }

  const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      await Auth.confirmSignUp(email, code);
      window.location.href = "/"
    } catch (error) {
      setErrors(error.message)
    }
    return false
  }
```


## Implement Custom Recovery Page
## Watch about different approaches to verifying JWTs

