import React from 'react';

export default function Queue(props) {
    const [timer, setTimer] = React.useState()
    const [queue, setQueue] = React.useState()


    function QueueItem({ item }) {
        return <div className="queueItem" key={`${item.distro}-${item.version}-${item.build}-${item.edition}`}>
            <span className="queueItemProduct">{item.product} ({item.distro})</span>
            <br />
            <span className="queueItemDetail">{item.edition}: {item.version}-{item.build}</span>
        </div>
    }

    function SubQueue({ status }) {
        const items = queue?.filter(item => item.status === status)
        if (!items) {
            return <div className="queueItem">Fetching...</div>
        } else if (items?.length === 0) {
            return <div className="queueItem">None</div>
        }
        return items?.map(x => <QueueItem key={`${x.distro}-${x.version}-${x.build}-${x.edition}-qi`} item={x} />)
    }

    React.useEffect(() => {
        function getQueue() {
            fetch(`http://${process.env.REACT_APP_API}/api/v1/queue`).then(res => res.json().then(x => {
                setQueue(x)
            })).catch(() => console.log("Queue empty"))
        }

        getQueue()
        if (!timer) {
            setTimer(setInterval(() => {
                getQueue()
            }, 10000))
        }
    }, [timer])

    return <div style={{ bottom: 0, overflow: "auto" }}>
        <div className="queueHeading">Processing:</div>
        <SubQueue status="processing" /><br />
        <div className="queueHeading">Queued:</div>
        <SubQueue status="queued" />
    </div>
}