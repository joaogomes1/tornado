// modules
const express = require('express');
const mysql = require('mysql');
const bcrypt = require("bcryptjs"); // password encryption

const app = express();

// environmental variables
const dotenv = require('dotenv');
dotenv.config();
// dotenv.config({path: './.env'})

const session = require('express-session');

// database connection
const db = mysql.createConnection({
    host: process.env.DATABASE_HOST,
    database: process.env.DATABASE,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD
})

db.connect((error) => {
    if(error) {
        console.log(error)
    }
    else {
        console.log("MySQL connected!")
    }
})


// session config
app.use(session({
    secret: 'secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 30000 }
  }));

// view engine
app.set('view engine', 'hbs')

// static assets
const path = require("path")
const publicDir = path.join(__dirname, './public')
app.use(express.static(publicDir))

// index routing
app.get("/", (req, res) => {
    const sessionData = req.session
    res.render("index")
})

// configure port
app.listen(5000, () => {
    console.log("server started on port 5000")
})

// register
app.get("/register", (req, res) => {
    res.render("register")
})

// login
app.get("/login", (req, res) => {
    res.render("login")
})

//// BACKEND

// receive form values as json
app.use(express.urlencoded({extended: 'false'}))
app.use(express.json())

// retrieve user's form values
app.post("/auth/register", (req, res) => {
    const {name, email, password, password_confirm} = req.body

    // field validation
    // to do: avoid erasing all fields in case of one is missing.
    // create a .js file for addressing field validation?
    if (name.trim().length === 0) {return res.render('register', {message: 'ops! you must insert a name'})}
    if (email.trim().length === 0) {return res.render('register', {message: 'ops! you must insert an e-mail'})}
    if (password.trim().length === 0) {return res.render('register', {message: 'ops! you must insert a password'})}
    if (password_confirm.trim().length === 0) {return res.render('register', {message: 'ops! you must confirm the password'})}
    if(password != password_confirm) {return res.render('register', {message: 'passwords do not match!'})}

    // query
    db.query('SELECT email FROM user WHERE email = ?', [email], async (error, res2) => {
        if(error) {
            console.log(error)
        }

        // email already exists.
        if(res2.length > 0) {
            return res.render('register', {
                message: 'this email is already in use.'
            })
        }

        // encrypt password
        let hashedPassword = await bcrypt.hash(password, 8)

        // feed database
        db.query('INSERT INTO user SET?', {name: name, email: email, password: hashedPassword}, (error, res3) => {
            if(error) {
                console.log(error)
            } else {
                return res.render('register', {
                    message: 'User registered successfully!'
                })
            }
        })


    })
})


// login
app.post("/auth/login", (req, res) => {

    if(req.session.isLoggedIn) {
        return res.render('index', {message: 'you are already logged in'})
    }
    
    const {email, password} = req.body

    // field validation
    if (email.trim().length === 0) {return res.render('login', {message: 'ops! you must insert an e-mail'})}
    if (password.trim().length === 0) {return res.render('login', {message: 'ops! you must insert a password'})}

    // query
    db.query('SELECT * FROM user WHERE email = ?', [email], async (error, res2) => {
        if(error) {
            console.log(error)
        }

        if (res2 && res2.length > 0) {
            bcrypt.compare(password, res2[0].password, function(err, result) {
                if(result) {
                    if(req.session.isLoggedIn) {
                        res.render('index', {message: 'you are already logged in'})
                    }
                    else {
                        req.session.isLoggedIn = true
                        req.session.email = email
                        res.render('index', {message: 'welcome!'})
                    }
                }
                else{
                    return res.render('login', {message: 'incorrect email or password'})
                }
            })
        }
        else {
            return res.render('login', {message: 'incorrect email or password'})
        }
        
    })

}) // method

app.get('/logout', (req, res) => {
    if (!req.session.isLoggedIn)
        return res.render('index', {message: 'you\'re not logged in'})
    else {
        req.session.destroy((err) => {
            if(err)
                console.log(err)
            else
                res.render('index', {message: 'user logged out sucessfully'})
        })
    }
}) // method





