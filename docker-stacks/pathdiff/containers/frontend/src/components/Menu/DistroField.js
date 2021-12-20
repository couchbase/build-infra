import React, { useEffect } from 'react';
import { Form, Label, Input, InputGroup } from 'reactstrap';
import { useApp } from '../../context/AppContext'
import { useHistory, useLocation } from "react-router-dom"

export default function MenuField(props) {
    const collator = new Intl.Collator(undefined, { numeric: true, sensitivity: 'base' });
    const history = useHistory()
    const location = useLocation()

    const {
        distro, setDistro,
        distros, setDistros,
        setToVisible
    } = useApp()

    const handleChange = (event) => {
        const params = new URLSearchParams(location.search)
        params.delete("distro")
        params.append("distro", event.target.value)
        history.push({ search: params.toString() })
        setToVisible(false)
        setDistro(event.target.value)
    };

    useEffect(() => {
        const apiUrl = `http://${process.env.REACT_APP_API}/api/v1/distros`
            fetch(apiUrl)?.then(res => res?.json()?.then(json => {
                if (!distro) setDistro(json[0])
                setDistros(json)
            })).catch(() => console.log("No distros found"))
    }, [distro, setDistro, setDistros])

    return (
        <Form>
            <InputGroup className="formRow">
                <Label className="formLabel">{props.heading}</Label>
                <Input className="formInput" type="select" name="select" onChange={handleChange}>get_l
                    {distros?.sort(collator.compare).map(d => {
                        if (distro === d) {
                            return <option key={d} selected value={d}>
                                {d?.split('-')?.[1] === 'GA' ? d?.split('-')?.[0] : d}
                            </option>
                        } else {
                            return <option key={d} value={d}>
                                {d?.split('-')?.[1] === 'GA' ? d?.split('-')?.[0] : d}
                            </option>
                        }
                    })
                    }
                </Input>
            </InputGroup>
        </Form>
    )
}
