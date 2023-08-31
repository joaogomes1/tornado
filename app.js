const express = require('express');
const mysql = require('mysql');
const dotenv = require('dotenv');

const app = express();

dotenv.config({ path: './.env'})

// const db = mysql.createConnection({
//     host: process.env.DATABASE_HOST,
//     user: process.env.DATABASE_USER,
//     password: process.env.DATABASE_PASSWORD,
//     database: process.env.DATABASE
// })
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'login_db'
})

console.log('>>>', typeof(db.user));

db.connect((error) => {
    if(error) {
        // console.log(error)
    }
    else {
        console.log("MySQL connected!")
    }
})

//
// app.set('view engine', 'hbs')

// //
// const path = require("path")

// const publicDir = path.join(__dirname, './public')

// app.use(express.static(publicDir))

// //
// app.get("/", (req, res) => {
//     res.render("index")
// })

// //
// app.listen(5000, () => {
//     console.log("server started on port 5000")
// })

// app.get("/register", (req, res) => {
//     res.render("register")
// })

// app.get("/login", (req, res) => {
//     res.render("login")
// })

// // backend
// const bcrypt = require("bcryptjs")

// app.use(express.urlencoded({extended: 'false'}))
// app.use(express.json())

// app.post("/auth/register", (req, res) => {
//     const {name, email, password, password_confirm} = req.body
//     // query
//     db.query('SELECT email FROM users WHERE email = ?', [email], async (error, res) => {
//         if(error) {
//             console.log(error)
//         }

//         if(result.length > 0) {
//             return res.render('register', {
//                 message: 'this email is already in use.'
//             })
//         }
//         else {
//             if (password !== password_confirm) {
//                 return res.render('register', {
//                     message: 'passwords do not match!'
//                 })
//             }
//         }
        
//         let hashedPassword = await bcrypt.hash(password, 8)


//     })
// })

    



