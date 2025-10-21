import React from 'react';
import './App.css';
import { Menu } from './components/Menu/'
import { Queue } from './components/Queue/'
import BinaryListing from './components/BinaryListing';
import { AppProvider } from './context/AppContext'
import Notifications from './components/Notifications'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'

function Main() {
    return <>
        <Notifications />
        <div id="page">
            <div id="container">
                <div id="sidebar">
                    <Menu /><br />
                    <Queue />
                </div>
                <div id="content">
                    <BinaryListing />
                </div>
            </div >
        </div>
    </>
}

function App() {
    return (
        <Router>
            <AppProvider>
                <Routes>
                    <Route path='/' component={Main} />
                </Routes>
            </AppProvider>
        </Router>
    );
}

export default App;
