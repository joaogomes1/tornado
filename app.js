const express = require('express');
const mysql = require('mysql');
const dotenv = require('dotenv');

const app = express();

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

// password encryption
const bcrypt = require("bcryptjs")


// receive form values as json
app.use(express.urlencoded({extended: 'false'}))
app.use(express.json())

// retrieve user's form values
app.post("/auth/register", (req, res) => {
    const {name, email, password, password_confirm} = req.body

    // query
    var result = db.query('SELECT email FROM user WHERE email = ?', [email], async (error, res) => {
        if(error) {
            console.log(error)
        }

        // email already exists.
        if(result.length > 0) {
            return res.render('register', {
                message: 'this email is already in use.'
            })
        }
        else {
            // passwords do not match
            if (password != password_confirm) {
                return res.render('register', {
                    message: 'passwords do not match!'
                })
            }
        }
        
        // encrypt password
        let hashedPassword = await bcrypt.hash(password, 8)

        // feed database
        db.query('INSERT INTO user SET?', {name: name, email: email, password: hashedPassword}, (error, res) => {
            if(error) {
                console.log(error)
            } else {
                return res.render('register', {
                    message: 'User registered!'
                })
            }
        })

    })
})

    



