import React, { useEffect, useState } from 'react';
import { Form, Label, Input, InputGroup } from 'reactstrap';
import { useApp } from '../../context/AppContext'
import { useNavigate, useLocation } from "react-router-dom"

export default function MenuField(props) {
    const [updater] = useState(props?.updater)
    const navigate = useNavigate()
    const location = useLocation()

    const {
        versions, setVersions,
        distro,
        toVersion,
        baseVersion, setBaseVersion
    } = useApp()

    const handleChange = (event) => {
        const params = new URLSearchParams(location.search)
        params.delete(props.type)
        params.append(props.type, event.target.value)
        navigate.push({ search: params.toString() })
        props.setter(event.target.value)
    };

    useEffect(() => {
        if (updater && distro) {
            const apiUrl = `http://${process.env.REACT_APP_API}/api/v1/versions?distro=${distro}`
            fetch(apiUrl).then(res => res.json().then(json => {
                if(!baseVersion || json.indexOf(baseVersion) === -1)
                    setBaseVersion(json[json.length-1])
                setVersions(json)
            }))
        }
    }, [distro, updater, setBaseVersion, setVersions, baseVersion])

    return (
        <Form>
            <InputGroup className="formRow">
                <Label className="formLabel">{props.heading}</Label>
                <Input className="formInput" type="select" name="select" onChange={handleChange}>
                    {versions?.map(v => {
                        if ((props.type === "baseVersion" && baseVersion === v) || (props.type === "toVersion" && toVersion === v)) {
                            return <option key={v} selected value={v}>{v?.split('-')?.[1] === 'GA' ? v?.split('-')?.[0] : v}</option>
                        } else {
                            return <option key={v} value={v}>{v?.split('-')?.[1] === 'GA' ? v?.split('-')?.[0] : v}</option>
                        }
                    })
                    }
                </Input>
            </InputGroup>
        </Form>
    )
}
