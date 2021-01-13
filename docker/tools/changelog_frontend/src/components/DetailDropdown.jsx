import React, { useState } from "react";
import { Input } from "reactstrap";
import {
  Dropdown,
  DropdownToggle,
  DropdownMenu,
  DropdownItem,
} from "reactstrap";

const semverSort = require("semver/functions/sort");
const semverRSort = require("semver/functions/rsort");

export default function DetailDropdown(props) {
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const toggle = () => setDropdownOpen((prevState) => !prevState);

  const handleKeyup = (event) => {
    if (event.keyCode === 13 && props.items.includes(event.target.value)) {
      props.setter(event.target.value);
      props.commit(true);
      toggle();
    }
  };

  function header(text) {
    if (text === "Build") {
      return <Input autoFocus type="text" onKeyUp={handleKeyup} />;
    }
    return text;
  }
  const detailList = (items, direction) => {
    let sorted;
    if(items && items.length > 0 && items.every(e => e.match(/^[0-9]+\.[0-9]+\.[0-9]+$/g)))  {
      if(direction === 'asc')
        sorted = semverSort(items);
      else
        sorted = semverRSort(items);
    } else {
      if(direction === 'asc')
        sorted = items.sort((a, b) => a.localeCompare(b))
      else
        sorted = items.sort((a, b) => b.localeCompare(a))
    }
    if(sorted && sorted[0] === "1006.5.1") {
      const mover = sorted[0]
      sorted = sorted.slice(1, sorted.length)
      sorted.push(mover)
    }
    return sorted.map(x => 
      <DropdownItem
        key={x}
        onClick={() => {
          props.setter(x);
          props.commit(true);
        }}
      >
        {x}
      </DropdownItem>
    )
  };

  return (
    <div>
      <Dropdown isOpen={dropdownOpen} toggle={toggle}>
        <DropdownToggle nav caret style={{ color: "#444" }}>
          {props.type}
        </DropdownToggle>
        <DropdownMenu style={{ overflowY: "scroll", maxHeight: 480 }}>
          <DropdownItem
            key={props.name}
            onClick={() => {
              props.setter(props.name);
              props.commit(true);
            }}
            header
          >
            {header(props.name)}
          </DropdownItem>
          <DropdownItem divider />
          {(props.items && detailList(props.items, props.direction)) || []}
        </DropdownMenu>
      </Dropdown>
    </div>
  );
}
