import React from 'react';
import { Alert } from 'reactstrap';
import { useApp } from '../context/AppContext'


export default function Notifications(props) {
    const {
        notificationMessage, notificationColor
    } = useApp()

    return <div id="notification">
        <Alert color={notificationColor} isOpen={notificationMessage === "" ? false : true}>
            {notificationMessage}
        </Alert>
    </div>
}