// dependencies?
const express = require('express');
const mysql = require('mysql');
const dotenv = require('dotenv');

const app = express();

const bcrypt = require("bcryptjs") // password encryption

// environmental variables
dotenv.config({path: './.env'})

// database connection
const db = mysql.createConnection({
    host: process.env.DATABASE_HOST,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE
})

db.connect((error) => {
    if(error) {
        console.log(error)
    }
    else {
        console.log("MySQL connected!")
    }
})

// view engine
app.set('view engine', 'hbs')

// static assets
const path = require("path")
const publicDir = path.join(__dirname, './public')
app.use(express.static(publicDir))

// index routing
app.get("/", (req, res) => {
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

    




        
        